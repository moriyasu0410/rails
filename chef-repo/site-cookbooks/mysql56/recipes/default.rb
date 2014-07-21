#
# Cookbook Name:: mysql56
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
package 'mysql-libs' do
  action :remove
end

remote_file "/tmp/#{node['mysql']['file_name']}" do
  source "#{node['mysql']['remote_uri']}"
end

bash "install_mysql" do
  user "root"
  cwd "/tmp"
  code <<-EOL
    tar xf "#{node['mysql']['file_name']}"
  EOL
end

node['mysql']['rpm'].each do |rpm|
  package rpm[:package_name] do
    action :install
    provider Chef::Provider::Package::Rpm
    source "/tmp/#{rpm[:rpm_file]}"
  end
end

service 'mysql' do
  action [ :enable, :start ]
end

bash "set_password" do
  user "root"
  not_if "mysql -u root -p#{node[:mysql][:password]} -e 'show databases'"
  code <<-EOL
    export Initial_PW=`head -n 1 /root/.mysql_secret |awk '{print $(NF - 0)}'`
    mysql -u root -p${Initial_PW} --connect-expired-password -e "SET PASSWORD FOR root@localhost=PASSWORD('#{node[:mysql][:password]}');"
    mysql -u root -p#{node[:mysql][:password]} -e "SET PASSWORD FOR root@'127.0.0.1'=PASSWORD('#{node[:mysql][:password]}');"
    mysql -u root -p#{node[:mysql][:password]} -e "FLUSH PRIVILEGES;"
  EOL
end
