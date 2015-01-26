Overview:
========
Functions to provision a simple 3-node cluster in trystack

- Sets up networks
- Configures ssh key
- creates floating ips
- creates a router and attaches it the external network
- boots centos7 nodes
- updates resolv.conf to use google dns

Running:
========

  source provision.sh
  
To run everything:

  main


