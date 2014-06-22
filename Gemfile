source 'https://rubygems.org'

gem 'berkshelf', '~> 3.1.1'

group :lint do
  gem 'foodcritic', '~> 4.0.0'
  gem 'rubocop', '~> 0.18'
  gem 'rainbow', '~> 2.0.0'
  gem 'rake'
end

group :unit do
  gem 'chefspec', '~> 3.4.0'
end

group :kitchen_common do
  gem 'test-kitchen', '~> 1.2.1'
  gem 'mixlib-shellout', '~> 1.2'
end

group :kitchen_vagrant do
  gem 'kitchen-vagrant', '~> 0.15'
end

platforms :mswin, :mingw do
    gem 'win32-service'    
    gem 'ruby-wmi'
end
