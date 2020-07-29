directory "#{node['cloud']['init']['install_dir']}/ec2init" do
  owner "root"
  group "root"
  mode "700"
end

template "#{node['cloud']['init']['install_dir']}/ec2init/run_ec2_init.sh" do
    source "run_ec2_init.sh.erb"
    user "root"
    group "root"
    mode 0500
end

template "#{node['cloud']['init']['install_dir']}/ec2init/run_ec2_update.sh" do
    source "run_ec2_update.sh.erb"
    user "root"
    group "root"
    mode 0500
end

template "#{node['cloud']['init']['install_dir']}/ec2init/deploy2glassfish_hook.sh" do
  source "deploy2glassfish_hook.sh.erb"
  user "root"
  group "root"
  mode 0500
end

template "#{node['cloud']['init']['install_dir']}/ec2init/ec2init_config.ini" do
  source "ec2init_config.ini.erb"
  user "root"
  group "root"
  mode 0500
end

cached_file = "ec2init-#{node['cloud']['init']['version']}-py3-none-any.whl"
source = "#{node['install']['enterprise']['download_url']}/ec2init/#{node['cloud']['init']['version']}/#{cached_file}"
remote_file "#{Chef::Config['file_cache_path']}/#{cached_file}" do
  user 'root'
  group 'root'
  source source
  headers get_ee_basic_auth_header()
  sensitive true
  mode 0555
  action :create_if_missing
end

case node["platform_family"]
when "debian"
  bash "add certbot repository" do
    user "root"
    group "root"
    code <<-EOF
      apt-get update
      apt-get install -y software-properties-common
      add-apt-repository -y universe
      add-apt-repository -y ppa:certbot/certbot
      apt-get update
    EOF
  end
  systemd_directory = "/lib/systemd/system"
when "rhel"
  package "epel-release"
  systemd_directory = "/usr/lib/systemd/system"
end

package "certbot"
package "curl"

template "#{systemd_directory}/ec2update.service" do
  source "ec2update.service.erb"
  owner "root"
  group "root"
  mode 0664
end

hopsworks_cn = consul_helper.get_service_fqdn("hopsworks.glassfish")
template "#{node['cloud']['init']['install_dir']}/ec2init/generate_glassfish_internal_x509.sh" do
    source "generate_glassfish_internal_x509.sh.erb"
    user 'root'
    group 'root'
    mode 0500
    variables({
        :hopsworks_cn => hopsworks_cn
    })
end