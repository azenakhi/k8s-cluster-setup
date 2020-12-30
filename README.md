# Setup kubernetes Cluster using kubeadm

## Create VMs
make -j 3 vm

## Create DNS
make dns

## Add fingerprints
make fingerprints

## Install Prerequisite 
make -j3 prerequisite

## Initialize Cluster
make init

## Add and Join Worker Node to Cluster
make -j 3 join

## Cleanup and delete Cluster
make clean