#!/bin/sh
ENCRYPT_FILE=$1

if [ ! -f "$ENCRYPT_FILE" ]; then
    echo -e "$ENCRYPT_FILE does not exist." | tee -a /tmp/aws-database-backup.log
    exit 1 
fi

if [ ! -z "$ENCRYPT_PASS" ] ; then
    if encoutput=$(openssl enc -aes-256-cbc -salt -in ${ENCRYPT_FILE} -out ${ENCRYPT_FILE}.tmp -k ${ENCRYPT_PASS})
    then
        rm "$ENCRYPT_FILE"
        mv "${ENCRYPT_FILE}.tmp" $ENCRYPT_FILE
        echo -e "The database backup successfully ecnrypted!"
    else
        echo -e "The database ecnrypt FAILED for $ENCRYPT_FILE. Error: $encoutput" | tee -a /tmp/aws-database-backup.log
        exit 1
    fi
else 
    echo "$ENCRYPT_FILE does not exist or paramers ENCRYPT_FILE and ENCRYPT_PASS does not set."
fi