#!/bin/bash
# retrieve passwords from secrets manager
PGPASSWORD=$DBPASSWORD pg_dump --no-password -h $RDSCONN -p $RDSPORT -U $DBUSER -d $DATABASE -v -Fc > /tmp/$APPLICATION_$ENVIRONMENT_db_backup_$(date '+%Y%m%d_%H%M%S').dump
