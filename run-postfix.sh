#!/bin/bash

set -ex

groupadd -g 5000 vmail || true
useradd -g vmail -u 5000 -d /var/mail/vmail -m vmail || true
chown -R vmail.vmail /var/mail/vmail
mkdir -p /var/spool/postfix/var/run/saslauthd || true

####################################################################
# Postfix stuff
####################################################################
# Need to copy these for so that postfix will find them becuase of chroot
cp -f /etc/services /var/spool/postfix/etc/
cp -f /etc/resolv.conf /var/spool/postfix/etc/

# Enable port 587 by uncommenting line in master.cf
sed -i '/submission.*inet.*smtpd/s/^#//g' /etc/postfix/master.cf

# Set the FQDN for mail server in /etc/mailname
sed -i 's/mail.replace.me/$MAIL_FQDN/g' /etc/mailname

/opt/postfix/conf/postfix/postfix_setup_mysql.sh
/opt/postfix/conf/postfix/postfix_setup_postconf.sh

####################################################################
# SASL stuff
####################################################################
cp -f /opt/postfix/conf/sasl/saslauthd /etc/default/

set +x -v
sed -e "s/\$POSTFIX_DB_HOST/$POSTFIX_DB_HOST/;
        s/\$POSTFIX_DB_NAME/$POSTFIX_DB_NAME/; 
        s/\$POSTFIX_DB_USER/$POSTFIX_DB_USER/;
        s/\$POSTFIX_DB_PASSWORD/$POSTFIX_DB_PASSWORD/" < /opt/postfix/conf/sasl/smtpd.conf.tmpl > /etc/postfix/sasl/smtpd.conf

sed -e "s/\$POSTFIX_DB_HOST/$POSTFIX_DB_HOST/;
        s/\$POSTFIX_DB_NAME/$POSTFIX_DB_NAME/;
        s/\$POSTFIX_DB_USER/$POSTFIX_DB_USER/;
        s/\$POSTFIX_DB_PASSWORD/$POSTFIX_DB_PASSWORD/" < /opt/postfix/conf/sasl/pam.d-smtp.tmpl > /etc/pam.d/smtp
set -x +v


####################################################################
# DKIM stuff
####################################################################
cp -f /opt/postfix/conf/dkim/opendkim /etc/default/

sed -e "s/\$MAIL_DOMAIN/$MAIL_DOMAIN/" < /opt/postfix/conf/dkim/opendkim.conf.tmpl > /etc/opendkim.conf


####################################################################
# Dovecot stuff
####################################################################

cp -f /opt/postfix/conf/dovecot/dovecot.conf /etc/dovecot/

set +x -v
sed -e "s/\$POSTFIX_DB_HOST/$POSTFIX_DB_HOST/;
        s/\$POSTFIX_DB_NAME/$POSTFIX_DB_NAME/;
        s/\$POSTFIX_DB_USER/$POSTFIX_DB_USER/;
        s/\$POSTFIX_DB_PASSWORD/$POSTFIX_DB_PASSWORD/" < /opt/postfix/conf/dovecot/dovecot-sql.conf.tmpl > /etc/dovecot/dovecot-sql.conf
set -x +v

service rsyslog restart
service saslauthd restart
service dovecot restart

postfix_status=`postfix status || true`
if [[ -z "${postfix_status##*$is running*}" ]]; then
    postfix stop
fi 

postfix start

tail -f /var/log/mail.log
