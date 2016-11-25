#!/bin/sh

# This file was created by Ansible.
# Manual changes will be lost.

# Don't add masquerading rule if it is already exists
/sbin/iptables -n -t nat -L POSTROUTING | /bin/grep -q MASQUERADE && exit 0 ||:

/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 
exit 0
