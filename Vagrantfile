# -*- mode: ruby -*-
# vi:set ft=ruby sw=2 ts=2 sts=2:

NUM_MASTER_NODE = 1
NUM_WORKER_NODE = 2

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2010"
  config.vm.box_check_update = false
  config.vm.network "forwarded_port", guest: 2222, host: 2222, id: "ssh", auto_correct: true

  # Provision Master Nodes
  (1..NUM_MASTER_NODE).each do |i|
      config.vm.define "master-#{i}" do |node|
        # Name shown in the GUI
        node.vm.provider "vmware_desktop" do |v|
            v.vmx["displayname"] = "master-#{i}"
            v.vmx["vvtd.enable"]= "True"
            v.vmx["vhv.enable"]= "True"
            v.vmx["virtualhw.version"] = "18"
            v.vmx["vhv.allow"] = "True"
            v.vmx["hypervisor.cpuid.0"] = "False"
            #v.gui = true
            v.vmx["memsize"] = "4096"
            v.vmx["numvcpus"] = "2"
        end
        node.vm.hostname = "master-#{i}"
      end
    end

  # Provision Worker Nodes
  (1..NUM_WORKER_NODE).each do |i|
    config.vm.define "worker-#{i}" do |node|
        node.vm.provider "vmware_desktop" do |v|
            v.vmx["displayname"] = "worker-#{i}"
            v.vmx["vvtd.enable"]= "True"
            v.vmx["vhv.enable"]= "True"
            v.vmx["virtualhw.version"] = "18"
            v.vmx["vhv.allow"] = "True"
            v.vmx["hypervisor.cpuid.0"] = "False"
            #v.gui = true
            v.vmx["memsize"] = "4096"
            v.vmx["numvcpus"] = "2"
        end
        node.vm.hostname = "worker-#{i}"
    end
  end
end