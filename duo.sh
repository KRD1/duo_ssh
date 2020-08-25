#!/bin/bash  
#Courtesy of M. McGrew
# install duo pam
    cd ~
    wget https://dl.duosecurity.com/duo_unix-latest.tar.gz
    tar zxf duo_unix-latest.tar.gz
    cd duo_unix-1.11.4
    ./configure --with-pam --prefix=/usr && make && sudo make install
    mkdir -p /etc/duo/
    echo """
[duo]
; Duo integration key
ikey = xxxx
; Duo secret key
skey = xxxx
; Duo API hostname
host = xxxx
    """ > /etc/duo/pam_duo.conf
    echo """
# here are the per-package modules (the "Primary" block)
auth    [success=1 default=ignore]      pam_unix.so nullok_secure
auth  requisite pam_unix.so
auth  [success=1 default=ignore] /lib64/security/pam_duo.so
auth  requisite pam_deny.so
auth  required pam_permit.so
""" > /etc/pam.d/common-auth
    echo """
# PAM configuration for the Secure Shell service
# Standard Un*x authentication.
#@include common-auth
auth  required pam_env.so
auth  requisite pam_unix.so
auth  [success=1 default=ignore] /lib64/security/pam_duo.so
auth  requisite pam_deny.so
auth  required pam_permit.so
# Disallow non-root logins when /etc/nologin exists.
account    required     pam_nologin.so
# Uncomment and edit /etc/security/access.conf if you need to set complex
# access limits that are hard to express in sshd_config.
# account  required     pam_access.so
# Standard Un*x authorization.
@include common-account
# SELinux needs to be the first session rule.  This ensures that any
# lingering context has been cleared.  Without this it is possible that a
# module could execute code in the wrong domain.
session [success=ok ignore=ignore module_unknown=ignore default=bad]        pam_selinux.so close
# Set the loginuid process attribute.
session    required     pam_loginuid.so
# Create a new session keyring.
session    optional     pam_keyinit.so force revoke
# Standard Un*x session setup and teardown.
@include common-session
# Print the message of the day upon successful login.
# This includes a dynamically generated part from /run/motd.dynamic
# and a static (admin-editable) part from /etc/motd.
session    optional     pam_motd.so  motd=/run/motd.dynamic
session    optional     pam_motd.so noupdate
# Print the status of the user's mailbox upon successful login.
session    optional     pam_mail.so standard noenv # [1]
# Set up user limits from /etc/security/limits.conf.
session    required     pam_limits.so
# Read environment variables from /etc/environment and
# /etc/security/pam_env.conf.
session    required     pam_env.so # [1]
# In Debian 4.0 (etch), locale-related environment variables were moved to
# /etc/default/locale, so read that as well.
session    required     pam_env.so user_readenv=1 envfile=/etc/default/locale
# SELinux needs to intervene at login time to ensure that the process starts
# in the proper default security context.  Only sessions which are intended
# to run in the user's context should be run after this.
session [success=ok ignore=ignore module_unknown=ignore default=bad]        pam_selinux.so open
# Standard Un*x password updating.
@include common-password """ > /etc/pam.d/sshd
