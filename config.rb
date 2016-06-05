# This file is called by Vagantfile. It will check if there is a "discovery"
# key in the user-data.etcd-hosts and, if there is, it will invoke the discovery
# URL to get a new token, and then update the user-data with the retrieved token.

# Used to fetch a new discovery token for a cluster of size $num_instances
$new_discovery_url="https://discovery.etcd.io/new?size=#{$num_etcd_instances}"

# Automatically replace the discovery token on 'vagrant up'

if File.exists?('user-data.etcd-hosts') && ARGV[0].eql?('up')
	require 'open-uri'
	require 'yaml'

	token = open($new_discovery_url).read

	data = YAML.load(IO.readlines('user-data.etcd-hosts')[1..-1].join)

	if data.key? 'coreos' and data['coreos'].key? 'etcd' and data['coreos']['etcd'].key? 'discovery'
		data['coreos']['etcd']['discovery'] = token
	end

	if data.key? 'coreos' and data['coreos'].key? 'etcd2' and data['coreos']['etcd2'].key? 'discovery'
		data['coreos']['etcd2']['discovery'] = token
	end

	# Fix for YAML.load() converting reboot-strategy from 'off' to `false`
	if data.key? 'coreos' and data['coreos'].key? 'update' and data['coreos']['update'].key? 'reboot-strategy'
		if data['coreos']['update']['reboot-strategy'] == false
			data['coreos']['update']['reboot-strategy'] = 'off'
		end
	end

	yaml = YAML.dump(data)
	File.open('user-data.etcd-hosts', 'w') { |file| file.write("#cloud-config\n\n#{yaml}") }
end
