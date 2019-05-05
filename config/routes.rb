Rails.application.routes.draw do
	namespace :api, defaults: { format: :json } do
		scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
			match 'doc',      to: 'docs#worker',   via: 'get'
			match 'doc',      to: 'docs#worker',   via: 'post'
			match 'validate', to: 'docs#validate', via: 'post'
			match 'merkle',   to: 'docs#merkle',   via: 'post'
			match 'status',   to: 'docs#status',   via: 'get'
		end
	end
	get "/doc" => redirect("/doc/")
end
