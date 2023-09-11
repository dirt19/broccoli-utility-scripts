#!/bin/bash

################################################################################
##
## modify-whitelist.sh
##
## Description:
## These functions are used to modify the elb-whitelist for AWS VPC
## 1) The purpose is to auth/revoke the whitelisted IP in case of DHCP change from ISP
## 2) "More secure" workflow would be to authorize as needed, then revoke on egress/logout
##
## Usage:
## $> saml2aws login -a aws-profile     ## must be logged in to the AWS account
## $> source modify_whitelist.sh
## $> revoke_stale_ip_by_description <description>
## $> authorize_whitelist authorize <description>
################################################################################


## -----------------------------------------------------------------------------
## Function: authorize_whitelist
##
## Purpose:
## Add or remove ingress permission rules for specific IPs
##
## Description:
## See https://docs.aws.amazon.com/cli/latest/reference/ec2/authorize-security-group-ingress.html for more info
##
## Arguments:
## 1. <optional> AUTHORIZE_REVOKE - ["authorize","revoke"] - command to allow or remove IPs
## 2. <optional> DESCRIPTION - ["description of rule for ip, e.g. name"] - Although optional, this is the "key"
##                           used to indicate which rules need to be removed when the IP is not able to be specified
## Notes:
## Revoke will throw an error if the IP/rule is not present
## -----------------------------------------------------------------------------
authorize_whitelist(){
    local SG_WHITELIST_ID="<default security group - sg-123456>"     # EC2 SecGrp elb-whitelist
    local AUTHORIZE_REVOKE=${1:-revoke}     # "authorize" "revoke": default to "revoke"
    local DESCRIPTION=${2:-description}
    local MY_IP="$(curl http://checkip.amazonaws.com/ >&1 2>/dev/null)/32"

    echo "Modifying whitelist"
    echo "IP CIDR: $MY_IP, Description: $DESCRIPTION, Action: $AUTHORIZE_REVOKE "

    aws --profile=dev ec2 $AUTHORIZE_REVOKE-security-group-ingress \
        --group-id $SG_WHITELIST_ID \
        --ip-permissions '[{"IpProtocol":"-1","IpRanges":[{"CidrIp":"'$MY_IP'","Description":"'$DESCRIPTION'"}]}]' 2>&1
}


## -----------------------------------------------------------------------------
## Function: revoke_stale_ip_by_description
##
## Purpose:
## Clear stale IPs from Ingress Permission Rules based on description
##
## Description:
## See https://docs.aws.amazon.com/cli/latest/reference/ec2/authorize-security-group-ingress.html for more info
##
## Arguments:
## 1. <optional> DESCRIPTION - ["description of rule for ip, e.g. name"]
##
## Notes:
## Revoke will throw an error if the IP/rule is not present
## -----------------------------------------------------------------------------
revoke_stale_ip_by_description(){
    local SG_WHITELIST_ID="<default security group - sg-123456>"
    local DESCRIPTION=${1:-description}
    local EXISTING_CIDR="$(aws --profile=dev ec2 describe-security-groups --group-ids $SG_WHITELIST_ID --output json | jq -r '.SecurityGroups[0].IpPermissions[1].IpRanges | map(select(.Description=="'$DESCRIPTION'"))[0].CidrIp')"

    echo "Revoking stale IP CIDR..."
    echo "IP CIDR: $EXISTING_CIDR, Description: $DESCRIPTION, Action: Revoke "

    aws --profile=dev ec2 revoke-security-group-ingress \
        --group-id $SG_WHITELIST_ID \
        --ip-permissions '[{"IpProtocol":"All", "IpRanges":[{"CidrIp":"'$EXISTING_CIDR'","Description":"'$DESCRIPTION'"}]}]' 2>&1
}