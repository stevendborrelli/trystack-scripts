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


function create_ssh_pubkey {
  nova keypair-add --pub-key ${SSH_PUBKEY} ${KEY_NAME}
}

function _create_network {
  neutron net-create network1
  neutron subnet-create network1 10.10.10.0/24 --name subnet1
}

function create_network {
  nova network-show network1 || _create_network
}
 
function _create_router {
  neutron router-create router1
  neutron router-gateway-set router1 external
  neutron router-interface-add router1 subnet1
}

function create_router {
  neutron router-show router1 || _create_router  
}

function create_floating_ips {
  for i in `seq 1 ${NUM_HOSTS}` ; do
    neutron floatingip-create external
  done
}

#start at index 1
function get_floating_ips {
  floating_ips=( skip $(nova floating-ip-list | grep external | awk '{print $2}') )
}

function create_ssh_pubkey {
  nova keypair-add --pub-key ${SSH_PUBKEY} ${KEY_NAME}
}

function default_sec_group {
  nova secgroup-add-rule ${SECURITY_GROUP} icmp -1 -1 0.0.0.0/0    #icmp ping
  nova secgroup-add-rule ${SECURITY_GROUP} tcp 22 22 0.0.0.0/0     #ssh
  nova secgroup-add-rule ${SECURITY_GROUP} tcp 5050 5050 0.0.0.0/0 #mesos-leader
  nova secgroup-add-rule ${SECURITY_GROUP} tcp 5051 5051 0.0.0.0/0 #mesos-follower
  nova secgroup-add-rule ${SECURITY_GROUP} tcp 8080 8080 0.0.0.0/0 #marathon
  nova secgroup-add-rule ${SECURITY_GROUP} tcp 8500 8500 0.0.0.0/0 #consul
  nova secgroup-add-rule ${SECURITY_GROUP} tcp 9090 9090 0.0.0.0/0 #mesos libprocess
}

function boot_instances {
  for i in `seq 1 ${NUM_HOSTS}`; do 
    nova boot --flavor ${FLAVOR} \
              --key_name ${KEY_NAME} \
              --image ${IMAGE} \
              --security_group ${SECURITY_GROUP} \
              --user-data user_data/data.txt \
              node1${i}
  done
}

function allocate_ips {
  floating_ips=( skip $(nova floating-ip-list | grep external | awk '{print $2}') )
  for i in `seq 1 ${NUM_HOSTS}`; do 
    echo "allocating ${floating_ips[${i}]} to node1${i}"
    nova floating-ip-associate node1${i} ${floating_ips[${i}]} 
  done
}

#Trystack nodes default resolv.conf doesn't work for
#external requests. Look into fixing via user_data
function resolv_conf {
  floating_ips=( $(nova floating-ip-list | grep external | awk '{print $2}') )
  for i in ${floating_ips[*]}; do
    echo -e "nameserver 8.8.8.8" > resolv.conf.tmp
    scp -o StrictHostKeyChecking=no resolv.conf.tmp centos@${i}:/tmp/resolv.conf
    ssh -o StrictHostKeyChecking=no -t centos@${i} "sudo cp /tmp/resolv.conf /etc/resolv.conf" 
    rm -f resolv.conf.tmp
  done
}

function main {
  create_ssh_pubkey
  create_network
  create_router
  create_floating_ips
  default_sec_group
  boot_instances

  sleep 5 && allocate_ips
  sleep 60 && resolv_conf
}

function inventory {
  floating_ips=( $(nova floating-ip-list | grep external | awk '{print $2}') )
  for i in `seq 1 ${NUM_HOSTS}`; do
    echo node1${i} ansible_ssh_host=${floating_ips[i]} ansible_ssh_user=centos
  done
}
