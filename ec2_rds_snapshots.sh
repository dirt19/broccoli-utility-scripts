# AWS_AVAIL_ZONE=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
# AWS_REGION=${AWS_AVAIL_ZONE::-1}

THISHOST=

# Determine the environment based on host name
RDSHOST=
DBINSTID=
RDSDB=
APP_ROOTVOL=
APP_DATAVOL=
INSTANCENAME=
PROFILE=
case "${THISHOST:2:1}" in
  d)
    RDSHOST=
    DBINSTID=
    RDSDB=
    APP_BACKVOL=
    APP_ROOTVOL=
    APP_DATAVOL=
    INSTANCENAME=
    PROFILE=
    ;;
  s)
    RDSHOST=
    DBINSTID=
    RDSDB=
    APP_ROOTVOL=
    APP_DATAVOL=
    INSTANCENAME=
    PROFILE=
    ;;
  p)
    RDSHOST=
    DBINSTID=
    RDSDB=
    APP_ROOTVOL=
    APP_DATAVOL=
    APP_BACKVOL=
    INSTANCENAME=
    PROFILE=
    ;;
esac

## Take Snapshots
#TODO: Snapshot creation permissions requires AWS::IAM change of scope (needs to be evaluated)
# RDS Snapshot
aws --profile=$PROFILE rds --region $AWS_REGION create-db-snapshot \
    --db-instance-identifier $DBINSTID \
    --db-snapshot-identifier $DBINSTID-jira-backup-pre
# Root Volume
aws --profile=$PROFILE ec2 --region $AWS_REGION create-snapshot --volume-id $JIRAROOTVOL \
    --description "$RDSDB-app01-root-pre" \
    --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=$RDSDB-app01-root-pre}]"
# Data Volume
aws --profile=$PROFILE ec2 --region $AWS_REGION create-snapshot --volume-id $JIRADATAVOL \
    --description "$RDSDB-app01-data-pre" \
    --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=$RDSDB-app01-data-pre}]"
# Backup Volume
aws --profile=$PROFILE ec2 --region $AWS_REGION create-snapshot --volume-id $JIRABACKVOL \
    --description "$RDSDB-app01-backup-pre" \
    --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=$RDSDB-app01-backup-pre}]"
