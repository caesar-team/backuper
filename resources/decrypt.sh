#!/bin/sh
DECRYPT_FILE=$1

if [ ! -f "$DECRYPT_FILE" ]; then
    echo -e "$DECRYPT_FILE does not exist." | tee -a /tmp/aws-database-backup.log
    exit 1 
fi

if [ ! -z "$ENCRYPT_PASS" ] ; then
    if encoutput=$(openssl enc -aes-256-cbc -d -pbkdf2 -in ${DECRYPT_FILE} -out ${DECRYPT_FILE}.tmp -k ${ENCRYPT_PASS})
    then
        rm "$DECRYPT_FILE"
        mv "${DECRYPT_FILE}.tmp" $DECRYPT_FILE
        echo -e "The database backup successfully decrypted!"
    else
        echo -e "The database ecnrypt FAILED for $DECRYPT_FILE. Error: $encoutput" | tee -a /tmp/aws-database-backup.log
        exit 1
    fi
else 
    echo "$DECRYPT_FILE does not exist or paramers DECRYPT_FILE and DECRYPT_PASS does not set."
fi