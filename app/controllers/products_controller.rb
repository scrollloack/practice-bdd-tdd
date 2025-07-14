class ProductsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :add_to_cart ]

  # rate_limit to: 4, within: 1.minute,
  #            by: -> { request.remote_ip },
  #            with: -> { redirect_to '/not_found' },
  #            only: %i[index add_to_cart]

  def index
    @products = GetProductsService.new.call

    render json: { 'data': @products }, status: 200
  end

  def add_to_cart
    user_id = session.id.to_s
    payload = params.require(:data).permit!

    code = payload[:code].to_s
    quantity = payload[:quantity].to_i

    unless quantity.positive?
      return render json: { 'error': 'Quantity must be greater than zero.' }, status: :bad_request
    end

    product = Product.find_by(code: code)

    if product.present?
      initial_cart = $redis.get(user_id)

      current_cart = initial_cart.present? ? JSON.parse(initial_cart) : {}

      item = current_cart[code] || {
        'code' => product.code,
        'name' => product.name,
        'price' => product.price.to_f,
        'quantity' => 0,
        'has_promo' => false,
        'charged_price' => 0.0
      }

      item['quantity'] = item['quantity'].to_i + quantity

      case code
      when 'GR1'
        has_promo = item['has_promo'] || false

        if !has_promo
          item['quantity'] += 1
          item['has_promo'] = true
        end

        if quantity == 2
          item['charged_price'] = product.price.to_f
        else
          charged_quantity = [ item['quantity'] - 1, 0 ].max
          item['charged_price'] = product.price.to_f * charged_quantity
        end
      when 'SR1'
        has_promo = item['has_promo'] || false

        if item['quantity'] >= 3 && !has_promo
          item['price'] = 4.50
          item['charged_price'] = item['price'].to_f * item['quantity'].to_i
          item['has_promo'] = true
        end
      end

      current_cart[code] = item

      $redis.set(user_id, current_cart.to_json)
      $redis.expire(user_id, 2.minutes)
      # $redis.expire(user_id, 1.hour)

      all_products = current_cart.values

      total_price = all_products.sum do |p|
        if p['code'] == 'GR1' && p['charged_price']
          p['charged_price'].to_f
        else
          p['price'].to_f * p['quantity'].to_i
        end
      end

      total_quantity = all_products.sum { |p| p['quantity'].to_i }

      data = {
        'products': all_products,
        'total_price': total_price.to_f.round(2),
        'total_quantity': total_quantity.to_i
      }

      render json: { 'data': data }, status: :ok
    else
      render json: { 'error': 'Product not found' }, status: :not_found
    end
  end
end
