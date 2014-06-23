require 'spec_helper'

describe 'npf::default' do
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

  let(:chef_run) do
    ChefSpec::Runner.new(:platform => 'centos', :version => '6.5') do |n|
      node.each do |attr, value|
        n.set[attr] = value
      end
    end.converge(described_recipe)
  end

  before do
    stub_command('which nginx').and_return(false)
    stub_command('test -d ' + pool_conf_dir + ' || mkdir -p ' + pool_conf_dir).and_return(true)
  end

  it 'installs nginx' do
    chef_run.should install_package('nginx')
  end

  it 'installs php' do
    chef_run.should install_package('php')
  end

  it 'installs php-fpm' do
    chef_run.should install_package(node['php-fpm']['service_name'])
  end

  it 'starts the service nginx' do
    chef_run.should start_service('nginx')
  end

  it 'starts the service ' + node['php-fpm']['service_name'] do
    chef_run.should start_service(node['php-fpm']['service_name'])
  end

  node[:deploy].each do |application, deploy|
    it 'creates ' + nginx_site_dir + '/' + application.to_s do
      chef_run.should create_template nginx_site_dir + '/' + application.to_s
    end

    # Initialize default listen option
    deploy[:domains].each do |server_alias|
      if server_alias != deploy[:domains].first
        it 'renders ' + nginx_site_dir + '/' + application.to_s + ' with content "server_name ' + server_alias + '"' do
          chef_run.should render_file(nginx_site_dir + '/' + application.to_s).with_content('server_name ' + server_alias)
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
        listen = listen.empty? && listen_first ? listen_first : listen
        listen_first ||= listen

        it 'renders ' + nginx_site_dir + '/' + application.to_s + ' with content "fastcgi_pass ' + listen + '"' do
          chef_run.should render_file(nginx_site_dir + '/' + application.to_s).with_content('fastcgi_pass ' + listen)
        end
      else
        next
      end
    end
  end
end
