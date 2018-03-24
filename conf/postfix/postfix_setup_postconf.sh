#!/bin/bash

set -ex

postconf -e "myhostname = $MAIL_FQDN"
postconf -e "mydomain = $MAIL_DOMAIN"
postconf -e "mydestination = $MAIL_FQDN, $MAIL_DOMAIN, localhost, localhost.localdomain"
postconf -e 'mail_spool_directory=/var/spool/mail/'
postconf -e 'mailbox_command='

postconf -e 'virtual_mailbox_domains = proxy:mysql:/etc/postfix/sql/mysql_virtual_domains_maps.cf'
postconf -e 'virtual_alias_maps = proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_maps.cf, proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_maps.cf, proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_catchall_maps.cf'
postconf -e 'virtual_mailbox_maps = proxy:mysql:/etc/postfix/sql/mysql_virtual_mailbox_maps.cf, proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_mailbox_maps.cf'
postconf -e 'virtual_mailbox_base = /var/mail/vmail'
postconf -e 'virtual_uid_maps = 5000'
postconf -e 'virtual_gid_maps = 5000'
postconf -e 'message_size_limit = 30720000'

postconf -e 'smtpd_sasl_auth_enable = yes'
postconf -e 'broken_sasl_auth_clients = yes'
postconf -e 'smtpd_sasl_authenticated_header = yes'
postconf -e 'smtpd_sasl_type = dovecot'
postconf -e 'smtpd_sasl_path = private/auth'
postconf -e 'smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination'
postconf -e 'smtpd_use_tls = yes'
postconf -e 'smtpd_tls_cert_file = /etc/postfix/tls/tls.crt'
postconf -e 'smtpd_tls_key_file = /etc/postfix/tls/tls.key'
postconf -e 'smtpd_tls_security_level = may'
postconf -e 'smtp_tls_security_level = may'
postconf -e 'smtp_tls_loglevel = 1'
postconf -e 'smtpd_tls_loglevel = 1'

# add header for authenticated mail to strip IP
postconf -e 'header_checks = regexp:/etc/postfix/header_checks'

# DKIM
postconf -e 'milter_default_action = accept'
postconf -e 'milter_protocol = 2'
postconf -e 'smtpd_milters = inet:127.0.0.1:8891'
postconf -e 'non_smtpd_milters = inet:127.0.0.1:8891'

# Uncomment this to enable HA Proxy protocol
postconf -e 'smtpd_upstream_proxy_protocol = haproxy'

# Sender Rewriting Scheme (SRS)
postconf -e 'sender_canonical_maps = tcp:127.0.0.1:10001'
postconf -e 'sender_canonical_classes = envelope_sender'
postconf -e 'recipient_canonical_maps = tcp:127.0.0.1:10002'
postconf -e 'recipient_canonical_classes = envelope_recipient,header_recipient'
