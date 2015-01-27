#!/bin/sh

#provisions a 3-node cluster in openstack
# this script expects Openstack environment variables
# like OS_TENANT_ID, OS_PASSWORD to be set

#requires
# pip install python-novaclient
# pip install python-neutronclient

NUM_HOSTS=3
FLAVOR=3   #m1.medium (3.75GB)
IMAGE=2e4c08a9-0ecd-4541-8a45-838479a88552 # CentOS 7 x86_64   
SECURITY_GROUP=default
KEY_NAME=ansible_key
SSH_PUBKEY=~/.ssh/id_rsa.pub


function delete_ssh_pubkey {
  nova keypair-delete ${KEY_NAME}
}

function delete_network {
  neutron subnet-delete subnet1
  neutron net-delete network1
}

function delete_router {
  neutron router-interface-delete router1 subnet1
  neutron router-gateway-clear router1 
  neutron router-delete router1
}

function delete_sec_group {
  nova secgroup-delete-rule ${SECURITY_GROUP} icmp -1 -1 0.0.0.0/0    #icmp ping
  nova secgroup-delete-rule ${SECURITY_GROUP} tcp 22 22 0.0.0.0/0     #ssh
  nova secgroup-delete-rule ${SECURITY_GROUP} tcp 5050 5050 0.0.0.0/0 #mesos-leader
  nova secgroup-delete-rule ${SECURITY_GROUP} tcp 5051 5051 0.0.0.0/0 #mesos-follower
  nova secgroup-delete-rule ${SECURITY_GROUP} tcp 8080 8080 0.0.0.0/0 #marathon
  nova secgroup-delete-rule ${SECURITY_GROUP} tcp 8500 8500 0.0.0.0/0 #consul
  nova secgroup-delete-rule ${SECURITY_GROUP} tcp 9090 9090 0.0.0.0/0 #mesos libprocess
}

function terminate_instances {
  for i in `seq 1 ${NUM_HOSTS}`; do 
    nova delete node1${i}
  done
}

function delete_ips {
  for i in `nova floating-ip-list | grep external | awk '{print $2}'`; do
    nova floating-ip-delete ${i}
  done
}

function main {
  terminate_instances
  delete_ips
}

function delete_all {
  terminate_instances
  delete_ips
  delete_router

  delete_network
  delete_sec_group
  delete_ssh_pubkey
}
