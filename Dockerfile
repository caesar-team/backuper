# Set the base image
FROM alpine:3.12

RUN apk -v --update add \
        python \
        py-pip \
        groff \
        less \
        mailcap \
        mariadb-client \
        postgresql \
        openssl \
        curl \
        && \
    pip install --upgrade awscli s3cmd python-magic && \
    apk -v --purge del py-pip && \
    rm /var/cache/apk/*

# Copy backup script and execute
COPY resources/* /
RUN chmod +x /mysql-backup.sh /pgsql-backup.sh /slack-alert.sh /crypt.sh
