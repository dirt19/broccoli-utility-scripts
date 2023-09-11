#!/bin/bash

################################################################################
##
## Password Rotation
##
## Description:
## This is to be used to rotate the credentials for App Admin and RDS access for
## AWS EC2 E-Tools applications. The purpose is to change the RDS credentials.
##
## Usage:
##    [root@etd-bb-app01 scripts]# source password_rotation.sh
##    [root@etd-bb-app01 scripts]# rotate_rds_credentials
##
## Notes:
## EC2 Instance Policies need to be updated to allow secretsmanager:Get*,UpdateSecret
##  AWS
##  IAM
##  Roles
##  <EC2>-instancerole...
##  Instance Policy
##  Edit Policy
##  SecretsManager
##  Actions
##  Write
##  Check:UpdateSecret
##  Review Policy
##  Save Changes
################################################################################

ENV_APP_VARS_MAPPING='{
    "hostname": {
        "application-hostname-here": {
            "secretname": "AWS-secret-mapping-here",
            "application": "application-short-name-here"
        }
    }
}'

## -----------------------------------------------------------------------------
## Function: get_aws_secret_by_secret_name
##
## Purpose:
## Reference AWS Secrets by Name (as a method to keep keys and passwords out of code)
##
## Description:
## See https://docs.aws.amazon.com/secretsmanager/latest/userguide/tutorials_basic.html#tutorial-basic-step2 for more info
##
## Arguments:
## 1. SECRETNAME - Name of Secret in AWS Secrets Manager
##
## Notes:
## | jq .Secret_Key ---> value - returns the value of the secret by key to the CLI
## -----------------------------------------------------------------------------
get_aws_secret_by_secret_name () {
    local AWS_AVAIL_ZONE=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
    local AWS_REGION=${AWS_AVAIL_ZONE::-1}
    local SECRETNAME=$1
    aws --region $AWS_REGION secretsmanager get-secret-value \
    --secret-id $SECRETNAME \
    --query SecretString \
    --output text
}


## -----------------------------------------------------------------------------
## Function: update_aws_secret_by_secret_name
##
## Purpose:
## Update secret in SecretsManager
##
## Description:
## Updates the secret in SecretsManager for human groking or other retrieval
##
## Arguments:
## 1. SECRETNAME - the name of the secret in AWS
## 3. THISPASS - the new password string
## 4. OLDSECRET - full string of old secret from AWS
##
## Notes:
## 1) Both `update-secret` and `put-secret-value` wipe out any
##      other fields in the secret so, 'update' them by doing
##      sed/jq gymnastics.
## -----------------------------------------------------------------------------
update_aws_secret_by_secret_name(){
    local SECRETNAME=$1
    local THISPASS=$2
    local OLDSECRET=$3

    local NEWSECRET=$(echo "$OLDSECRET" | jq '.password = "'$THISPASS'"' | jq --compact-output .)

    local AWS_AVAIL_ZONE=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
    local AWS_REGION=${AWS_AVAIL_ZONE::-1}
    aws --region $AWS_REGION secretsmanager update-secret \
    --secret-id $SECRETNAME \
    --secret-string $NEWSECRET
}


## -----------------------------------------------------------------------------
## Function: generate_password
##
## Purpose:
## Generate or retrieve a password
##
## Description:
## Either generate a simple enough password or retrive it one from LP or AWS SecretsManager
##
## Arguments:
## 1. <optional> LASTPASS - not built yet
## 2. <optional> AWSSECRETS - not built yet
##
## Notes:
## previous method: $(date +%s | sha256sum | base64 | head -c 32 ; echo)
## -----------------------------------------------------------------------------
generate_password(){
    local FROM_LASTPASS=${1:-none}
    local FROM_AWSSECRETS=${2:-none}
    local otherpass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 48 | head -n 1)
    echo $otherpass
}


## -----------------------------------------------------------------------------
## Function: change_sql_user_password
##
## Purpose:
## Change the sql user password
##
## Description:
## Log into the SQL database and change the password for that user
##
## Arguments:
## 1. DBUSER - e.g. ["appdev","appprod", etc.]
## 2. OLDPASS - e.g. ["SoM3P4SSwordThatwASGENerATed"]
## 3. NEWPASS - e.g. ["0THerP4SSwordThatwASGENerATed"]
##
## Notes:
##
## -----------------------------------------------------------------------------
change_sql_user_password(){
    local DBUSER=$1
    local OLDPASS=$2
    local NEWPASS=$3
    local HOSTPREFIX=$(echo $THISHOSTNAME | awk -F'-' '{print $1}')

    # DBHOST could probably also be retrieved from the AWS::SecretsManager
    if [[ "$HOSTPREFIX" == "etp" ]]; then
        local DBHOST="postgres-db-hostname-here.us-west-2.rds.amazonaws.com"
    else
        local DBHOST="$HOSTPREFIX.us-west-2.rds.amazonaws.com"   # default database
    fi

    PGPASSWORD=$OLDPASS psql --no-password -c "ALTER ROLE $DBUSER WITH PASSWORD '$NEWPASS';" -h $DBHOST -U $DBUSER postgres
}


## -----------------------------------------------------------------------------
## Function: change_db_connection
##
## Purpose:
## Change the db connection password for app
##
## Description:
## Change the db connection information in the connection file
##
## Arguments:
## 1. NEWPASS - new password to change to
##
## Notes:
## Artifactory encrypts the plaintext password after application restart
## -----------------------------------------------------------------------------
change_db_connection(){
    local NEWPASS=$1
    local ec2appkey=$(echo $THISHOSTNAME | awk -F'-' '{print $2}') # selects mapping from hostname

    if [[ $ec2appkey =~ "THIS-APPLICATION-NAME" ]]; then
        local FILE="/var/atlassian/application-data/THIS-APPLICATION-NAME/THIS-APPLICATION-NAME.cfg.xml"
        sed -i -e 's/\(.*hibernate\.connection\.password.*>\).*\(<\/property>\)/\1'$NEWPASS'\2/' $FILE

    elif [[ "$ec2appkey" == "OTHER-APP" ]]; then
        local FILE="/opt/OTHER-APP/current/conf/OTHER-APP.properties"
        sed -i -e 's/\(OTHER-APP\.jdbc\.password=\).*/\1'$NEWPASS'/' $FILE

    else
        echo "No DB connection files modified"
    fi
}


## -----------------------------------------------------------------------------
## Function: rotate_rds_credentials
##
## Purpose:
## Update credential in LastPass
##
## Description:
## Updates the credential in LastPass for human groking or other retrieval
##
## Arguments:
##
## Notes:
##
## -----------------------------------------------------------------------------
rotate_rds_credentials(){

    THISHOSTNAME=$(hostname)
    APPLICATION=$(echo $ENV_APP_VARS_MAPPING | jq -r ".hostname.\"$THISHOSTNAME\".application")
    local SECRETNAME=$(echo $ENV_APP_VARS_MAPPING | jq -r ".hostname.\"$THISHOSTNAME\".secretname")

    echo "---------------------------------------------------------------------------"
    echo "Rotating RDS Credentials: $THISHOSTNAME\n"
    echo "---------------------------------------------------------------------------"
    echo "getting secret"
    AWSSECRET=$(get_aws_secret_by_secret_name $SECRETNAME)
    SQL_USER=$(echo $AWSSECRET | jq -r .username)
    OLD_PASS=$(echo $AWSSECRET | jq -r .password)
    echo "---------------------------------------------------------------------------"
    echo "getting new pw"
    NEW_PASS=$(generate_password; echo)

    ### Placed here in case one of the change functions below fails ###
    # A temporary place to reference to SecretsManager
    #             and LastPass can be manually updated
    local secretslog="/root/secrets.log"
    echo $(date '+%Y%m%d%H%M%S') > $secretslog
    echo $SECRETNAME >> $secretslog
    echo $OLD_PASS >> $secretslog
    echo $NEW_PASS >> $secretslog
    echo "writing secrets.log"
    echo "---------------------------------------------------------------------------"
    echo "service stop"

    service $APPLICATION stop
    sleep 15

    echo "---------------------------------------------------------------------------"
    echo "change db connection: file"
    change_db_connection $NEW_PASS
    echo "change db connection: dbuser"
    change_sql_user_password $SQL_USER $OLD_PASS $NEW_PASS
    echo "update db connection: aws secret"
    update_aws_secret_by_secret_name $SECRETNAME $NEW_PASS $AWSSECRET

    echo "---------------------------------------------------------------------------"
    echo "Update LP from /root/secrets.log"
    echo "---------------------------------------------------------------------------"

    # Just part of weekly maintenance
    yum -y update
    shutdown -r now
}
