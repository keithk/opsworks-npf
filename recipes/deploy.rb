include_recipe 'deploy'

node['deploy'].each do |application, deploy|

  opsworks_deploy do
    app application
    deploy_data deploy
  end

end
