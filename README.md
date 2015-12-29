## Ansible for DigitalOcean VPN

This is a set of scripts and playbooks for setting up an OpenVPN endpoint using DigitalOcean.

All examples below imply that you have setup inventory.

## Overview
This is a fork of [https://github.com/timurb/ansible-digitalocean-vpn](https://github.com/timurb/ansible-digitalocean-vpn). Once Ansible 2.0 packages are more common, I'll raise a pull request to merge this.


### Changes from https://github.com/timurb/ansible-digitalocean-vpn
* The teardown functionality from https://github.com/timurb/ansible-digitalocean-vpn is not present in this fork - this will be replaced soon with a solution that does not require ruby or tugboat
* pip replaces easy_install
* Static key is generated during the installation
* Suports Ansible v2 and DigitalOcean v2 API

## Requirements
These playbooks use the v2 API from DigitalOcean and this requires that you be using Ansible v2 or later. As of December 2015, this means deploying from source - see http://docs.ansible.com/ansible/intro_installation.html#getting-ansible for instructions.

As well as Ansible v2, you will also need to ensure that you have a recent version of setuptools installed on your Ansible control machine. You can do this as follows:
```bash
sudo apt-get install python-setuptools
```

## Autodeploy of VPN server to [Digital Ocean](http://digitalocean.com/)

You can use ansible to create a DigitalOcean droplet for you prior to installing OpenVPN onto it.

To do that you need to   

* Generate an access token at [https://cloud.digitalocean.com/settings/applications#access-tokens](https://cloud.digitalocean.com/settings/applications#access-tokens) (this needs to have 'Write' scope). Make sure that you note this token somewhere because it will not be displayed again!
* Get your ssh key id using `curl -H "Authorization: Bearer <YOUR ACCESS TOKEN>" https://api.digitalocean.com/v2/account/keys` from the commandline
* Create file `host_vars/localhost` under your ansible configuration directory (e.g. `/etc/ansible/host_vars/localhost`)
and add the following:

```yaml
do_api_token: Your access token
do_ssh_key_id: Your SSH Key ID
```
* Make sure you can login to localhost by SSH and sudo to root if running ansible as a non-privileged account

When you have the above in place you run the command:
```
./create_vpn.sh
```
This will create a DigitalOcean droplet, install OpenVPN and configure it.

**Important:** If you use `ansible-playbook vpn_digital_ocean.yml` to deploy the instead and you don't have passwordless sudo set up on localhost you must run the command with `-K` key (e.g. `ansible-playbook -K vpn_digital_ocean.yml`)
or ansible will hang infinitely.

## Setting up on an existing host
The following steps can be used to setup OpenVPN on an existing host instead of creating a new host. The same can be achieved by running `./createvpn.sh --nocreate`

You need to have a server in your inventory named `vpn` for this to work. This will be added if you auto-deploy a DigitalOcean droplet using the autodeploy playbook.

### Base image
Sets up the basic server with `vim`, `git` installed, `nano` uninstalled etc.

Usage:
```bash
ansible-playbook bootstrap.yml
```

### OpenVPN server

Sets up the OpenVPN server configured to use with static key.

* Check the list of variables in `vpn.yml` and adjust them to your needs. The main things that you're likely to need to change are 
    * server_addr - tunnel IP on server
	* client_addr - tunnel IP on client
	* openvpn_cd - OpenVPN config directory
* Run `ansible-playbook vpn.yml`

If there are no errors you'll have the OpenVPN server set up and running in around a minute.

## Setting up the client
**TODO** Add cient setup as a playbook and add roles for server and client
To configure your Ubuntu box to connect to this server do the following:

### If you're using a graphical desktop
* Install NetworkManager OpenVPN plugin: `sudo apt-get install network-manager-openvpn-gnome`
* Add the OpenVPN connection from NetworkManager menu:
 * Enter the IP address of your server
 * Select "Static key authentication"
 * Choose `static.key` you've generated a while ago
 * Enter value from the playbook for `server_addr` into "Remote address" field and value for `client_addr` into "Local address".
* Try to connect to VPN using this connection
* Check that you are really using VPN: `curl ipecho.net/plain`

### Server / command-line setup
These steps work on Ubuntu 

* Install OpenVPN: `apt-get install openvpn`
* Copy `/etc/openvpn/static.key` from the vpn server to /etc/openvpn/static.key on your client using a secure method 
* Create a config file `/etc/openvpn/client.conf` with the contents listed below
* Start OpenVPN: `/etc/init.d/openvpn start`

**/etc/openvpn/client.conf**
`
remote <IP Address of VPN server> 1194
dev tun
secret static.key
ifconfig <client_addr> <server_addr>
route-up "sbin/route add default gw <server_addr>"
proto udp
persist-key
persist-tun
comp-lzo
verb 3
`

## Routing
If you want all traffic to go via your VPN, you need to do a few extra things:

* Setup a static route to the public IP address of your VPN server
* Add a route when the VPN starts

You may wish to reboot your client after these steps if you're not comfortable manipulating routes manually.

### Static Route
Modify /etc/network/interfaces and remove the default gateway. Then add a line similar to the following to your primary interface section:

`up route add -host <public_ip_of_vpn> gw <your_gateway>`

### VPN Route
Add the following to /etc/openvpn/client.conf
`route-up "/sbin/route add default gw <server_addr>"`

## Contributing

Pull requests are welcome

## License and Author

* Author:: Timur Batyrshin
* License:: Apache 2.0
