require 'sinatra'
require 'stripe'
require 'json'
require 'dotenv'

Dotenv.load
Stripe.api_key = ENV['STRIPE_SECRET_KEY']

get '/' do
  'Relay Proxy'
end

get '/products' do
	Stripe::Product.all.to_json
end

get '/products/:id' do |id|
	Stripe::Product.retrieve(id)
end
