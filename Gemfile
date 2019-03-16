source 'https://rubygems.org'
source 'file:///usr/src/app/merkle-hash-tree'
#source 'file:///Users/christoph/oyd/blockchain/api-blockchain/merkle-hash-tree'

gem 'rails', '~> 5.1.6'
gem 'pg'
gem 'puma', '~> 3.7'
gem 'rack-cors', require: 'rack/cors'
gem 'jbuilder'
gem 'httparty'
gem 'merkle-hash-tree', path: '/usr/src/app/merkle-hash-tree'
#gem 'merkle-hash-tree', path: '/Users/christoph/oyd/blockchain/api-blockchain/merkle-hash-tree'
gem 'responders'
gem 'rack-reverse-proxy', :require => "rack/reverse_proxy"
gem 'rbnacl'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'better_errors'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'annotate'
end
