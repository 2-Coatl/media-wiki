# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define "mediawiki-db01" do |db|
    db.vm.box = "ubuntu/focal64"
    db.vm.hostname = "mediawiki-db01"

    db.vm.network "private_network",
                  ip: "10.0.2.20",
                  virtualbox__intnet: "internal-app"

    db.vm.provider "virtualbox" do |vb|
      vb.name = "mediawiki-db01"
      vb.memory = "1024"
      vb.cpus = 1
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end

    db.vm.synced_folder ".", "/vagrant",
                        owner: "vagrant",
                        group: "vagrant"

    db.vm.provision "shell",
                    path: "infrastructure/provisioners/provision_database.sh",
                    run: "once"
  end

  config.vm.define "mediawiki-web01", primary: true do |web|
    web.vm.box = "ubuntu/focal64"
    web.vm.hostname = "mediawiki-web01"

    web.vm.network "public_network",
                   ip: "192.168.1.100",
                   bridge: [
                     "en0: Wi-Fi (AirPort)",
                     "Ethernet",
                     "Wi-Fi",
                     "eth0",
                     "wlan0"
                   ]

    web.vm.network "private_network",
                   ip: "10.0.2.10",
                   virtualbox__intnet: "internal-app"

    web.vm.provider "virtualbox" do |vb|
      vb.name = "mediawiki-web01"
      vb.memory = "2048"
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end

    web.vm.synced_folder ".", "/vagrant",
                         owner: "vagrant",
                         group: "vagrant"

    web.vm.provision "shell",
                     path: "infrastructure/provisioners/provision_web_server.sh",
                     run: "once"
  end

end
