include_recipe 'nginx'
include_recipe 'php-fpm'

node['deploy'].each do |application, deploy|

  if deploy[:application_type] != 'php'
    Chef::Log.debug("Skipping web application #{application} as it is not a PHP app")
    next
  end

  nginx_web_app application do
    template 'php-fpm-site.erb'
    cookbook 'npf'
    application deploy
    docroot deploy[:absolute_document_root]
    server_name deploy[:domains].first
    php_fpm_service_name node['php-fpm']['service_name']
    php_fpm_pools node['php-fpm']['pools']
    domain_pools deploy[:domain_pools]
    unless deploy[:domains][1, deploy[:domains].size].empty?
      server_aliases deploy[:domains][1, deploy[:domains].size]
    end
    ssl_certificate_ca deploy[:ssl_certificate_ca]
    only_if { node['php-fpm'] && node['php-fpm']['pools'] }
  end
end

service node['php-fpm']['service_name'] do
  action :start
end
