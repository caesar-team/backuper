#!/bin/sh


# Set the has_failed variable to false. This will change if any of the subsequent database backups/uploads fail.
has_failed=false
getnow() {
    date +"%m-%d-%Y_%H-%M-%S"
}
now="$(getnow)"

# Loop through all the defined databases, seperating by a ,
for CURRENT_DATABASE in ${TARGET_DATABASE_NAMES//,/ }
do
    filename=${CURRENT_DATABASE}_${now}.sql.tar.gz
    # Perform the database backup. Put the output to a variable. If successful upload the backup to S3, if unsuccessful print an entry to the console and the log, and set has_failed to true.
    if sqloutput=$(mysqldump -u $DB_USER -h $DB_HOST -p$DB_PASSWORD -P $DB_PORT $CURRENT_DATABASE 2>&1 > /tmp/$filename)
    then
        
        echo -e "Database backup successfully completed for ${filename} at $(getnow)."
        
        if [ "$ENCRYPT" = true ]; then
            if encoutput=$(/crypt.sh /tmp/"${filename}")
            then
                echo -e "Database backup successfully encrypted for $CURRENT_DATABASE at $(getnow)."
            else
                echo -e ":no_entry: Database backup failed to encrypt for *$CURRENT_DATABASE* at *$(getnow)*. ``$(Error: "$awsoutput")``" | tee -a /tmp/aws-database-backup.log
                has_failed=true
            fi
        fi

        # Perform the upload to S3. Put the output to a variable. If successful, print an entry to the console and the log. If unsuccessful, set has_failed to true and print an entry to the console and the log
        if awsoutput=$(aws s3 cp /tmp/"$filename" s3://"$AWS_BUCKET_NAME""$AWS_BUCKET_BACKUP_PATH"/"${filename}" 2>&1)
        then
            echo -e "Database backup successfully uploaded for $CURRENT_DATABASE at $(getnow)."
        else
            echo -e ":no_entry: Database backup failed to upload for $CURRENT_DATABASE at $(getnow). *Error*: ``$($awsoutput)``" | tee -a /tmp/aws-database-backup.log
            has_failed=true
        fi

    else
        echo -e ":no_entry: Database backup FAILED for $CURRENT_DATABASE at $(getnow). *Error*: ``$($sqloutput)``" | tee -a /tmp/aws-database-backup.log
        has_failed=true
    fi

done



# Check if any of the backups have failed. If so, exit with a status of 1. Otherwise exit cleanly with a status of 0.
if [ "$has_failed" = true ]
then

    # If Slack alerts are enabled, send a notification alongside a log of what failed
    if [ "$SLACK_ENABLED" = true ]
    then
        # Put the contents of the database backup logs into a variable
        logcontents=$(cat /tmp/aws-database-backup.log)

        # Send Slack alert
        /slack-alert.sh "One or more backups on databases *$TARGET_DATABASE_NAMES* failed. The error details are included below:" "``$($logcontents)``"
    fi

    echo -e "aws-database-backup encountered 1 or more errors. Exiting with status code 1."
    exit 1

else

    # If Slack alerts are enabled, send a notification that all database backups were successful
    if [ "$SLACK_ENABLED" = true ]
    then
        /slack-alert.sh "All database backups successfully completed for databases *$TARGET_DATABASE_NAMES*."
    fi

    exit 0
    
fi