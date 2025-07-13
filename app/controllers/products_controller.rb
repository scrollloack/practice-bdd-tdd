class ProductsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :add_to_cart ]

  rate_limit to: 4, within: 1.minute,
             by: -> { request.remote_ip },
             with: -> { redirect_to '/not_found' },
             only: %i[index add_to_cart]

  def index
    @products = GetProductsService.new.call

    render json: { 'data': @products }, status: 200
  end

  def add_to_cart
    user_id = session.id.to_s
    payload = params.require(:data).permit!

    code = payload[:code].to_s
    quantity = payload[:quantity].to_i

    product = Product.find_by(code: code)

    initial_cart = $redis.get(user_id)

    current_cart = initial_cart.present? ? JSON.parse(initial_cart) : {}

    item = current_cart[code] || {
      'code' => product.code,
      'name' => product.name,
      'price' => product.price.to_f,
      'quantity' => 0
    }

    item['quantity'] = item['quantity'].to_i + quantity
    current_cart[code] = item

    $redis.set(user_id, current_cart.to_json)
    $redis.expire(user_id, 1.hour)

    all_products = current_cart.values
    total_price = all_products.sum { |p| p['price'].to_f * p['quantity'].to_i }
    total_quantity = all_products.sum { |p| p['quantity'].to_i }

    data = {
      'products': all_products,
      'total_price': total_price,
      'total_quantity': total_quantity
    }

    render json: { 'data': data }, status: :ok
  end
end
