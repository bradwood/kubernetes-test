# -*- mode: ruby -*-
# # vi: set ft=ruby :
# Hacked from https://github.com/coreos/coreos-vagrant/blob/master/Vagrantfile
# Removed references to VMWare. Only works with VirtualBox.
# -- github@bradleywood.com
#
require 'fileutils'

Vagrant.require_version ">= 1.6.0"

#files needed yy the CoreOS Bootstrap. Make sure to include in the same dir as
#this file.
MINION_CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), "user-data.minions")
ETCD_CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), "user-data.etcd-hosts")

#general ruby config file -- used by all CoreOS based hosts (Ie, etcd and minions)
CONFIG = File.join(File.dirname(__FILE__), "config.rb")

# coreos-vagrant is configured through a series of configuration
# options (global ruby variables) which are detailed below. To modify
# these options, uncomment the necessary lines, leaving the $, and
# replace everything after the equals sign.

# etcd hosts config
# =================
# how many hosts in the etcd cluster?
$num_etcd_instances = 2

# Change basename of the etcd hosts
$etcd_name_prefix = "etcd"

# minions hosts config
# ====================
# how many hosts in the minion (worker) cluster?
$num_instances = 2

# Change basename of the etcd hosts
$instance_name_prefix = "minion"

# General settings; these apply to all CoreOS-based hosts
# =======================================================
# Official CoreOS channel from which updates should be downloaded
# options are "stable", "beta" and "alpha"
$update_channel = "stable"

# Change the version of CoreOS to be installed
# To deploy a specific version, simply set $image_version accordingly.
# For example, to deploy version 709.0.0, set $image_version="709.0.0".
# The default value is "current", which points to the current version
# of the selected channel
$image_version = "current"

# Log the serial consoles of CoreOS VMs to log/
# Enable by setting value to true, disable with false
# WARNING: Serial logging is known to result in extremely high CPU usage with
# VirtualBox, so should only be used in debugging situations
$enable_serial_logging = false

# Enable port forwarding of Docker TCP socket
# Set to the TCP port you want exposed on the *host* machine, default is 2375
# If 2375 is used, Vagrant will auto-increment (e.g. in the case of $num_instances > 1)
# You can then use the docker tool locally by setting the following env var:
# export DOCKER_HOST='tcp://127.0.0.1:2375'
#$expose_docker_tcp=2375

# Enable NFS sharing of your home directory ($HOME) to CoreOS
# It will be mounted at the same path in the VM as on the host.
# Example: /Users/foobar -> /Users/foobar
$share_home = false

# Customize VMs
$vm_gui = false
$vm_memory = 1024
$vm_cpus = 1

# Share additional folders to the CoreOS VMs
# For example,
# $shared_folders = {'/path/on/host' => '/path/on/guest', '/home/foo/app' => '/app'}
# or, to map host folders to guest folders of the same name,
# $shared_folders = Hash[*['/home/foo/app1', '/home/foo/app2'].map{|d| [d, d]}.flatten]
$shared_folders = {}

# Enable port forwarding from guest(s) to host machine, syntax is:
# { 80 => 8080 }, auto correction is enabled by default.
$forwarded_ports = {}

# # Attempt to apply the deprecated environment variable NUM_INSTANCES to
# # $num_instances while allowing config.rb to override it
# if ENV["NUM_INSTANCES"].to_i > 0 && ENV["NUM_INSTANCES"]
#   $num_instances = ENV["NUM_INSTANCES"].to_i
# end

# loads in the CONFIG file and executes it inline.
# this is primarily to set a new discovery token for
# the etcd cluster.
if File.exist?(CONFIG)
  require CONFIG
end

# Use old vb_xxx config variables when set
def vm_gui
  $vb_gui.nil? ? $vm_gui : $vb_gui
end

def vm_memory
  $vb_memory.nil? ? $vm_memory : $vb_memory
end

def vm_cpus
  $vb_cpus.nil? ? $vm_cpus : $vb_cpus
end

Vagrant.configure("2") do |config|
  # always use Vagrant's insecure key
  config.ssh.insert_key = false

  config.vm.box = "coreos-%s" % $update_channel
  if $image_version != "current"
      config.vm.box_version = $image_version
  end
  config.vm.box_url = "https://storage.googleapis.com/%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant.json" % [$update_channel, $image_version]

  # ["vmware_fusion", "vmware_workstation"].each do |vmware|
  #   config.vm.provider vmware do |v, override|
  #     override.vm.box_url = "https://storage.googleapis.com/%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant_vmware_fusion.json" % [$update_channel, $image_version]
  #   end
  # end

  config.vm.provider :virtualbox do |v|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end


	# set up etcd hosts
  (1..$num_etcd_instances).each do |i|
    config.vm.define vm_name = "%s-%02d" % [$etcd_name_prefix, i] do |config|
      config.vm.hostname = vm_name

      if $enable_serial_logging
        logdir = File.join(File.dirname(__FILE__), "log")
        FileUtils.mkdir_p(logdir)

        serialFile = File.join(logdir, "%s-serial.txt" % vm_name)
        FileUtils.touch(serialFile)

        # ["vmware_fusion", "vmware_workstation"].each do |vmware|
        #   config.vm.provider vmware do |v, override|
        #     v.vmx["serial0.present"] = "TRUE"
        #     v.vmx["serial0.fileType"] = "file"
        #     v.vmx["serial0.fileName"] = serialFile
        #     v.vmx["serial0.tryNoRxLoss"] = "FALSE"
        #   end
        # end

        config.vm.provider :virtualbox do |vb, override|
          vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
          vb.customize ["modifyvm", :id, "--uartmode1", serialFile]
        end
      end

      if $expose_docker_tcp
        config.vm.network "forwarded_port", guest: 2375, host: ($expose_docker_tcp + i - 1), auto_correct: true
      end

      $forwarded_ports.each do |guest, host|
        config.vm.network "forwarded_port", guest: guest, host: host, auto_correct: true
      end

      # ["vmware_fusion", "vmware_workstation"].each do |vmware|
      #   config.vm.provider vmware do |v|
      #     v.gui = vm_gui
      #     v.vmx['memsize'] = vm_memory
      #     v.vmx['numvcpus'] = vm_cpus
      #   end
      # end

      config.vm.provider :virtualbox do |vb|
        vb.gui = vm_gui
        vb.memory = vm_memory
        vb.cpus = vm_cpus
      end

      ip = "172.17.2.#{i+100}"
      config.vm.network :private_network, ip: ip

      # Uncomment below to enable NFS for sharing the host machine into the coreos-vagrant VM.
      #config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      $shared_folders.each_with_index do |(host_folder, guest_folder), index|
        config.vm.synced_folder host_folder.to_s, guest_folder.to_s, id: "core-share%02d" % index, nfs: true, mount_options: ['nolock,vers=3,udp']
      end

      if $share_home
        config.vm.synced_folder ENV['HOME'], ENV['HOME'], id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      end

      if File.exist?(ETCD_CLOUD_CONFIG_PATH)
        config.vm.provision :file, :source => "#{ETCD_CLOUD_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
        config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
      end

    end
  end

  # sets up the minions
  (1..$num_instances).each do |i|
    config.vm.define vm_name = "%s-%02d" % [$instance_name_prefix, i] do |config|
      config.vm.hostname = vm_name

      if $enable_serial_logging
        logdir = File.join(File.dirname(__FILE__), "log")
        FileUtils.mkdir_p(logdir)

        serialFile = File.join(logdir, "%s-serial.txt" % vm_name)
        FileUtils.touch(serialFile)

        # ["vmware_fusion", "vmware_workstation"].each do |vmware|
        #   config.vm.provider vmware do |v, override|
        #     v.vmx["serial0.present"] = "TRUE"
        #     v.vmx["serial0.fileType"] = "file"
        #     v.vmx["serial0.fileName"] = serialFile
        #     v.vmx["serial0.tryNoRxLoss"] = "FALSE"
        #   end
        # end

        config.vm.provider :virtualbox do |vb, override|
          vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
          vb.customize ["modifyvm", :id, "--uartmode1", serialFile]
        end
      end

      if $expose_docker_tcp
        config.vm.network "forwarded_port", guest: 2375, host: ($expose_docker_tcp + i - 1), auto_correct: true
      end

      $forwarded_ports.each do |guest, host|
        config.vm.network "forwarded_port", guest: guest, host: host, auto_correct: true
      end

      # ["vmware_fusion", "vmware_workstation"].each do |vmware|
      #   config.vm.provider vmware do |v|
      #     v.gui = vm_gui
      #     v.vmx['memsize'] = vm_memory
      #     v.vmx['numvcpus'] = vm_cpus
      #   end
      # end

      config.vm.provider :virtualbox do |vb|
        vb.gui = vm_gui
        vb.memory = vm_memory
        vb.cpus = vm_cpus
      end

      ip = "172.17.8.#{i+100}"
      config.vm.network :private_network, ip: ip

      # Uncomment below to enable NFS for sharing the host machine into the coreos-vagrant VM.
      #config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      $shared_folders.each_with_index do |(host_folder, guest_folder), index|
        config.vm.synced_folder host_folder.to_s, guest_folder.to_s, id: "core-share%02d" % index, nfs: true, mount_options: ['nolock,vers=3,udp']
      end

      if $share_home
        config.vm.synced_folder ENV['HOME'], ENV['HOME'], id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
      end

      if File.exist?(MINION_CLOUD_CONFIG_PATH)
        config.vm.provision :file, :source => "#{MINION_CLOUD_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
        config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
      end

    end
  end

# now setting up the Ubuntu management box.
  config.vm.define "mgmt" do |mgmt|
  	# use a recent ubuntu server
  	mgmt.vm.box="ubuntu/trusty64"
  	# run a bootstrapper script to set up the ubuntu mgmt host.
  	# mgmt.vm.provision :shell, path: "ubuntu-mgmt-box-bootstrap.sh"
  	# give this box a static IP outside the range of the coreOS boxes
  	mgmt.vm.network :private_network, ip: "172.17.8.50"
  	# use vagrant's ssh key
  	mgmt.ssh.insert_key = false
  	# TODO: load tools
  end # mgmt box config
end
