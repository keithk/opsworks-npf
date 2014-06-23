include_recipe 'nginx::service'
include_recipe 'php-fpm::service'

node['deploy'].each do |application, deploy|

  if deploy[:application_type] != 'php'
    Chef::Log.debug("Skipping web application #{application} as it is not a PHP app")
    next
  end

  service 'nginx' do
    action :restart
  end

  service node['php-fpm']['service_name'] do
    action :restart
  end

end
