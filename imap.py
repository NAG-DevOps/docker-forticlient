#!/usr/bin/env python
#
# Very basic example of using Python and IMAP to iterate over emails in a
# gmail folder/label.  This code is released into the public domain.
#
# RKI July 2013
# http://www.voidynullness.net/blog/2013/07/25/gmail-email-with-python-via-imap/
#
import sys
import imaplib
import getpass
import email
import email.header
import datetime
import time

EMAIL_ACCOUNT = sys.argv[1]
EMAIL_PASSWORD = sys.argv[2]
EMAIL_SMTP = sys.argv[3]
EMAIL_FOLDER = "INBOX"


def process_mailbox(M):
    found = 0
    while found != 1:
        rv, data = M.search(None, "(UNSEEN)", "SUBJECT", "AuthCode:")
        if rv != 'OK':
           print "No messages found!"
           return

        for num in data[0].split():
            rv, data = M.fetch(num, '(RFC822)')
            found = 1
            if rv != 'OK':
                print "ERROR getting message", num
                return

            msg = email.message_from_string(data[0][1])
            decode = email.header.decode_header(msg['Subject'])[0]
            subject = unicode(decode[0])
            sub, authcode = subject.split(": ")
            print '%s' % (authcode)
            fount = 1
        time.sleep(5)


M = imaplib.IMAP4_SSL(EMAIL_SMTP)

try:
    rv, data = M.login(EMAIL_ACCOUNT, EMAIL_PASSWORD)
except imaplib.IMAP4.error:
    sys.exit(1)


rv, data = M.select(EMAIL_FOLDER)
if rv == 'OK':
    process_mailbox(M)
    M.close()
else:
    print "ERROR: Unable to open mailbox ", rv

M.logout()

