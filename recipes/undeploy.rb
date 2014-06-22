include_recipe 'deploy'
include_recipe 'nginx::service'

node['deploy'].each do |application, deploy|

  if deploy[:application_type] != 'php'
    Chef::Log.debug("Skipping web application #{application} as it is not a PHP app")
    next
  end

  link "#{node['nginx']['dir']}/sites-enabled/#{application}" do
    action :delete
    only_if do
      ::File.exist?("#{node['nginx']['dir']}/sites-enabled/#{application}")
    end
    notifies :restart, 'service[nginx]'
  end

  directory deploy[:deploy_to] do
    recursive true
    action :delete
    only_if do
      ::File.exist?(deploy[:deploy_to])
    end
  end

end
