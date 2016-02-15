# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'fileutils'

config_file=File.expand_path(File.join(File.dirname(__FILE__), 'vagrant_variables.yml'))
settings=YAML.load_file(config_file)

NMONS        = ENV["VMS"] || settings['vms']
SUBNET       = settings['subnet']
BOX          = settings['vagrant_box']
BOX_VERSION  = settings['box_version']
MEMORY       = settings['memory']

NO_PROXY = '192.168.2.10,192.168.2.11,192.168.2.80,192.168.2.81'

shell_provision = <<-EOF
echo "export http_proxy='$1'" >> /etc/profile.d/envvar.sh
echo "export https_proxy='$2'" >> /etc/profile.d/envvar.sh
echo "export no_proxy='#{NO_PROXY}'" >> /etc/profile.d/envvar.sh

. /etc/profile.d/envvar.sh
EOF

ansible_provision = proc do |ansible|
  ansible.playbook = 'ansible/site.yml'
  # Note: Can't do ranges like mon[0-2] in groups because
  # these aren't supported by Vagrant, see
  # https://github.com/mitchellh/vagrant/issues/3539
  ansible.groups = {
    'netplugin-node' => (0..NMONS - 1).map { |j| "mon#{j}" },
  }

  proxy_env = {
    "no_proxy" => NO_PROXY
  }

  %w[HTTP_PROXY HTTPS_PROXY http_proxy https_proxy].each do |name|
    if ENV[name]
      proxy_env[name] = ENV[name]
    end
  end

  # In a production deployment, these should be secret
  ansible.extra_vars = {
    docker_version: "1.10.1",
    etcd_peers_group: 'netplugin-node',
    env: proxy_env,
    control_interface: "enp0s8",
    netplugin_if: "enp0s9",
    cluster_network: "#{SUBNET}.0/24",
    public_network: "#{SUBNET}.0/24",
    service_vip: "192.168.2.10",
    validate_certs: 'no',
	scheduler_provider: 'ucp-swarm',
  }
  ansible.limit = 'all'
end



Vagrant.configure(2) do |config|
  #config.vm.box = "box-cutter/ubuntu1504"
  config.vm.box = BOX
  config.vm.box_version = BOX_VERSION
  config.vm.synced_folder ".", "/opt/demo"

  (0..NMONS - 1).each do |i|
	config.vm.define "mon#{i}" do |mon|
		mon.vm.hostname = "mon#{i}"

		mon.vm.network "private_network", virtualbox__intnet: true, ip: "192.168.2.1#{i}"
		mon.vm.network "private_network", virtualbox__intnet: true, ip: "192.168.2.8#{i}"

        mon.vm.provision "shell" do |s|
          s.inline = shell_provision
          s.args = [ ENV["http_proxy"] || "", ENV["https_proxy"] || "" ]
        end

        # Run the provisioner after the last machine comes up
        mon.vm.provision 'ansible', &ansible_provision if i == (NMONS - 1)
	end
  end

end
