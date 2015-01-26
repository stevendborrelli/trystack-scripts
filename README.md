Overview:
========
Functions to provision a simple 3-node cluster in trystack

- Sets up networks
- Configures ssh key
- creates floating ips
- creates a router and attaches it the external network
- boots centos7 nodes
- updates resolv.conf to use google dns


Requirements
============


- Account on http://trystack.org
- Install Openstack Clients:

		pip install python-novaclient
		pip install python-neutronclient

- Have openstack environment environment varibles similar to this:

		export OS_AUTH_URL=http://8.21.28.222:5000/v2.0
		export OS_TENANT_ID=<sha_string>
		export OS_TENANT_NAME="facebookXXXXX"
		export OS_USERNAME="facebookXXXXX"
		export OS_PASSWORD=<trystack api key>
		export OS_REGION_NAME="RegionOne"


Note: the `OS_AUTH_URL` can be obtained from the Instances->Access & Security->API Access in the Openstack console. 


Running:
========

  	source provision.sh
  
To run everything:

  	main
  	
  	
Each function can be run separately. 

Functions:
=========

	create_ssh_pubkey: uploads youd id_rsa as ansible_key
	
	create_network: creates  network1

	create_router: creates router1

	create_floating_ips: creates external floating ips

	get_floating_ips

	default_sec_group: sets up inbound rules for the default security group

	boot_instances: launches CentosInstances

	allocate_ips: allocates external IPs to instances

	resolv_conf: Point resolv.conf to 8.8.8.8
	
	main: run all functions

