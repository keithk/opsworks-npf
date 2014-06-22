require 'serverspec'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

RSpec.configure do |c|
  c.before :all do
    c.path = '/sbin:/usr/sbin'
  end
end

# Set nginx conf
nginx_site_dir = '/etc/nginx/sites-available'

# Set php-fpm service name
php_fpm_service_name = 'php-fpm'
version = ''
conf_file = '/etc/' + php_fpm_service_name + (!version.empty? ? '-' + version : '') + '.conf'
pool_conf_dir = '/etc/' + php_fpm_service_name + (!version.empty? ? '-' + version : '') + '.d'

# Set node attribute
node = {
  'opsworks' => { 'ruby_stack' => 'ruby' },
  'php' => { 'packages' => %w(php php-fpm) },
  'php-fpm' => {
    'service_name' => php_fpm_service_name,
    'version' => version,
    'conf_file' => conf_file,
    'pool_conf_dir' => pool_conf_dir,
    'pid' => '/var/run/php-fpm' + (version.empty? ? '' : '/' + version) + '/php-fpm.pid',
    'error_log' => '/var/log/php-fpm/error.log',
    'log_level' => 'notice',
    'emergency_restart_threshold' => 0,
    'emergency_restart_interval' => 0,
    'process_control_timeout' => 0,
    'pools' => [
      {
        'name' => 'www',
        'process_manager' => 'dynamic',
        'max_children' => 50,
        'start_servers' => 5,
        'min_spare_servers' => 5,
        'max_spare_servers' => 35,
        'max_requests' => 500,
        'catch_workers_output' => 'no',
        'security_limit_extensions' => '.php',
        'slowlog' => '/var/log/php-fpm/slow.log',
        'php_options' => {
          'php_admin_value[memory_limit]' => '128M',
          'php_admin_value[error_log]' => '/var/log/php-fpm/@version@poolerror.log',
          'php_admin_flag[log_errors]' => 'on',
          'php_value[session.save_handler]' => 'files',
          'php_value[session.save_path]' => '/var/lib/php/@versionsession'
        }
      },
      {
        'name' => 'backend'
      }
    ]
  },
  :deploy => {
    :test => {
      :application => 'test',
      :application_type => 'php',
      :deploy_to => '/srv/www/test',
      :user => 'deploy',
      :group => 'nginx',
      :domains => %w(test.dev.com www.test.dev.com backend.test.dev.com),
      :domain_pools => {
        'www.test.dev.com' => 'www',
        'backend.test.dev.com' => 'backend'
      }
    }
  }
}
pools = node['php-fpm']['pools']

describe package('nginx') do
  it { should be_installed }
end

describe package('php') do
  it { should be_installed }
end

describe package('php-fpm') do
  it { should be_installed }
end

describe service('nginx') do
  it { should be_running }
end

describe service(php_fpm_service_name) do
  it { should be_running }
end

describe file(conf_file) do
  it { should be_file }
end

describe file(pool_conf_dir) do
  it { should be_directory }
end

node[:deploy].each do |application, deploy|
  describe file(nginx_site_dir + '/' + application.to_s) do
    it { should be_file }
  end

  # Initialize default listen option
  listen_first = ''
  deploy[:domains].each do |server_alias|
    if server_alias != deploy[:domains].first
      describe file(nginx_site_dir + '/' + application.to_s) do
        it { should contain 'server_name ' + server_alias }
      end

      # Get php-fpm pool listen option for the domain
      listen = ''
      if deploy[:domain_pools] && deploy[:domain_pools][server_alias]
        pool_name = deploy[:domain_pools][server_alias]
        pools.each do |pool|
          if pool['name'] == pool_name
            if pool['listen']
              listen = pool['listen']
            else
              listen = "unix:/var/run/#{php_fpm_service_name}-#{pool_name}.sock"
            end
          else
            next
          end
        end
      else
        listen = pools.first[:listen]
      end

      # Use default listen
      if listen.empty? && !listen_first.empty?
        listen = listen_first
      else
        listen_first = listen_first.empty? ? listen : listen_first
      end

      describe file(nginx_site_dir + '/' + application.to_s) do
        it { should contain 'fastcgi_pass ' + listen }
      end
    else
      next
    end
  end
end
