require 'sinatra'
require 'stripe'
require 'json'
require 'dotenv'
require 'encrypted_cookie'

Dotenv.load
Stripe.api_key = ENV['STRIPE_SECRET_KEY']
use Rack::Session::EncryptedCookie,
  :secret => ENV['STONE_SESSION_SECRET']

get '/' do
  'Relay Proxy'
end

post '/sessions' do
	customer = Stripe::Customer.create(
		:metadata => {'device_identifier' => params[:device_identifier]}
	)
	session[:customer_id] = customer.id
end

get '/products' do
	Stripe::Product.all(limit: 100).to_json
end

get '/products/:id' do |id|
	Stripe::Product.retrieve(id).to_json
end

post '/orders' do
	Stripe::Order.create(params).to_json
end


get '/cards' do
  authenticate!

  status 200
  content_type :json
  cards = customer.sources.all(:object => "card")
  selected_card = cards.find {|c| c.id == customer.default_source}
  return { :cards => cards.data, selected_card: selected_card }.to_json

end

post '/sources/:source' do
  authenticate!
  halt 400 unless params[:source]

  customer.sources.create({:source => source})
  200
end

post '/customers/:customer/select_source' do
  authenticate!
  halt 400 unless params[:source]

  customer.default_source = source
  customer.save
  
  200
end

def authenticate!
  halt 401 unless customer
end

def customer
  return @customer if @customer
  return nil unless session[:customer_id]
  customer_id = session[:customer_id]
  begin
    @customer = Stripe::Customer.retrieve(customer_id)
  rescue Stripe::InvalidRequestError do |e|
  end
  @customer
end
