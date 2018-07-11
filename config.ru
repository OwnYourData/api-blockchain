# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'
use Rack::ReverseProxy do
  reverse_proxy(/^\/doc(\/.*)$/, 'https://blockchain-doc.ownyourdata.eu$1', opts = {:preserve_host => true})
end
use Rack::Deflater

run Rails.application
