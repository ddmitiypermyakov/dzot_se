# -*- mode: ruby -*-
# vim: set ft=ruby :


MACHINES = {
  :selinux => {
        :box_name => "oracle/8",
        #:box_version => "2004.01",
        #:provision => "test.sh",       
  },
}


Vagrant.configure("2") do |config|


  MACHINES.each do |boxname, boxconfig|


      config.vm.define boxname do |box|


        box.vm.box = boxconfig[:box_name]
        box.vm.box_version = boxconfig[:box_version]


        box.vm.host_name = "selinux"
        box.vm.network "forwarded_port", guest: 4881, host: 4881


        box.vm.provider :virtualbox do |vb|
              vb.customize ["modifyvm", :id, "--memory", "1024"]
              needsController = false
        end


      box.vm.provision "shell", path: "dz_se_p1.sh", name: "part1"

    end
  end
end
