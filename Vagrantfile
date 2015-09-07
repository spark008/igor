# -*- mode: ruby -*-
# vi: set ft=ruby :

# Supported values:
# ubuntu-vivid, fedora-22, fedora-23
OS = 'fedora-22'

# Number of worker VMs.
WORKERS = 1

Vagrant.configure(2) do |config|
  config.vm.box = {
    'ubuntu-vivid' => 'ubuntu/vivid64',
    'fedora-22' => 'fedora-server-cloud-22',
    'fedora-23' => 'fedora-server-cloud-23',
  }[OS]
  config.vm.box_check_update = true

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.network :private_network, type: :dhcp, nic_type: 'virtio'

  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', '/home/vagrant/sync', disabled: true

  # NOTE: The master is the primary machine so that we can "vagrant ssh" into
  #       it without having to provide extra arguments.
  config.vm.define "master", primary: true do |master|
  end

  1.upto WORKERS do |worker_id|
    config.vm.define "worker#{worker_id}" do |worker|
      # NOTE: The ansible provisioning block is only defined in the last
      #       worker, so it runs after all the VMs have been created.
      if worker_id == WORKERS
        config.vm.provision :ansible do |ansible|
          ansible.playbook = "deploy/ansible/prod.yml"
          ansible.limit = "all"

          # Simulate the groups produced by the OpenStack setup.
          ansible.groups = {
            "meta-system_role_algprod_master" => ["master"],
            "meta-system_role_algprod_worker" =>
                (1..WORKERS).map { |i| "worker#{i}" },
          }
          ansible.extra_vars = {
            os_image_user: "vagrant",
          }

          # Uncomment for Ansible connection debugging.
          # ansible.verbose = "vvvv"
          # ansible.verbose = "vvv"
        end
      end
    end
  end

  config.vm.provider :virtualbox do |vb, override|
    vb.memory = 1024
    override.vm.box_url = {
      'fedora-22' => "https://download.fedoraproject.org/pub/fedora/linux/releases/22/Cloud/x86_64/Images/Fedora-Cloud-Base-Vagrant-22-20150521.x86_64.vagrant-virtualbox.box",
      'fedora-23' => "http://dl.fedoraproject.org/pub/alt/stage/23_Beta_TC1/Cloud_Images/x86_64/Images/Fedora-Cloud-Base-Vagrant-23_Beta_TC1-20150826.x86_64.vagrant-virtualbox.box",
    }[OS]

    # The NAT network adapter uses the Intel PRO/1000MT adapter by default.
    vb.customize ['modifyvm', :id, '--nictype1', 'virtio']
  end

  config.vm.provider :libvirt do |domain, override|
    domain.memory = 1024
    override.vm.box_url = {
      'fedora-22' => "https://download.fedoraproject.org/pub/fedora/linux/releases/22/Cloud/x86_64/Images/Fedora-Cloud-Base-Vagrant-22-20150521.x86_64.vagrant-libvirt.box",
      'fedora-23' => "http://dl.fedoraproject.org/pub/alt/stage/23_Beta_TC1/Cloud_Images/x86_64/Images/Fedora-Cloud-Base-Vagrant-23_Beta_TC1-20150826.x86_64.vagrant-libvirt.box",
    }[OS]
  end
end
