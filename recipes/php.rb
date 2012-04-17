#
# Cookbook Name:: newrelic
# Recipe:: php
#
# Copyright 2011, Skystack Limited
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
require_recipe "newrelic_agent::default"

package "newrelic-php5" do
  action :install
  options "--force-yes"
end

directory '/etc/newrelic' do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

execute "run_newrelic-installer" do
  command "chmod +x /tmp/newrelic-installer;/tmp/newrelic-installer;touch /opt/skystack/tmp/executed-newrelic-installer;"
  action :nothing
 
  only_if do ! File.exists?( "/opt/skystack/tmp/executed-newrelic-installer" ) end
end

bash "newrelic-installer" do
  interpreter "sh"
  user "root"
  cwd "/tmp"
  code <<-EOH
#!/bin/sh
export NR_INSTALL_SILENT=true
echo "newrelic::php line 49 executing /usr/bin/newrelic-install in install mode" >> /var/log/install 2>&1
/usr/bin/newrelic-install "install"
EOH
  notifies :run, resources(:execute => "run_newrelic-installer")
  creates "/tmp/newrelic-installer"
end

template "/etc/php5/conf.d/newrelic.ini" do
  source "newrelic.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :appname => node[:newrelic_agent][:appname],
    :params => node
  )
  notifies :restart, resources(:service => "apache2"), :immediately
end


template "/etc/newrelic/newrelic.cfg" do
  source "newrelic.cfg.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :license_key => node[:newrelic_agent][:license_key],
    :loglevel => node[:newrelic_agent][:loglevel],
    :logfile => node[:newrelic_agent][:logfile],
    :pidfile => node[:newrelic_agent][:pidfile],
    :collector => node[:newrelic_agent][:daemon][:collector_host]
  )
end


template "/etc/newrelic/newrelic.yml" do
  source "newrelic.yml.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :license_key => node[:newrelic_agent][:license_key],
    :appname => node[:newrelic_agent][:appname],
    :params => node
  )
end


service "newrelic-daemon" do
 action [ :enable, :restart ]
end

execute "run-newrelic-daemon" do
  command "/etc/init.d/newrelic-daemon restart"
  action :run
end

