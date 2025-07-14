require 'rails_helper'

RSpec.describe '/products', type: :request do
  let!(:key) { 'cart:test-user' }
  let!(:mock_redis) { instance_double('Redis') }

  describe 'GET /index' do
    let(:products) { build_stubbed_list(:product, 3) }
    let(:service) { double }

    before do
      allow(GetProductsService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(products)
    end

    context 'when products exists' do
      it 'returns a json response of products' do
        get '/products'
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data'].length).to eq(products.length)
        expect(json_response['data'].map { |p| p['id'] }).to match_array(products.map(&:id))
      end
    end

    context 'when no products exist' do
      let(:products) { [] }

      it 'returns an empty json response' do
        get '/products'
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data']).to eq([])
      end
    end
  end

  describe 'POST /products/add_to_cart' do
    let(:charged_price) { 0.0 }
    let(:code) { 'some_product_code' }
    let(:has_promo) { false }
    let(:param_quantity) { 1 }
    let(:price) { 10.00 }
    let(:product_name) { 'some_product_name' }
    let(:quantity) { 1 }
    let(:total_price) { price }
    let(:total_quantity) { quantity }

    let(:cart_item) do
      {
        'code' => code,
        'name' => product_name,
        'price' => price,
        'quantity' => quantity,
        'has_promo' => has_promo,
        'charged_price' => charged_price
      }
    end
    let(:cart_result) do
      {
        'products' => [ cart_item ],
        'total_price' => total_price,
        'total_quantity'=> total_quantity
      }
    end
    let(:params_data) do
      {
        'data': {
          'code': code,
          'quantity': param_quantity
        }
      }
    end
    let(:product) do
      build_stubbed(
        :product,
        code: code,
        name: product_name,
        price: price
      )
    end

    before do
      allow(Product).to receive(:find_by).with(code: code).and_return(product)
      allow(mock_redis).to receive(:get).and_return(nil)
      allow(mock_redis).to receive(:set)
      allow(mock_redis).to receive(:expire)
      $redis = mock_redis
    end

    context 'when adding a product to the cart' do
      it 'returns a JSON response of the added product' do
        post '/products/add_to_cart', params: params_data

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data']).to eq(cart_result)
      end
    end

    context 'when adding a green tea product to the cart' do
      let(:charged_price) { 10.0 }
      let(:code) { 'GR1' }
      let(:has_promo) { true }
      let(:param_quantity) { 1 }
      let(:product_name) { 'Green Tea' }
      let(:quantity) { 2 }
      let(:total_quantity) { quantity }

      it 'returns a JSON response with the buy 1 get 1 promo details' do
        post '/products/add_to_cart', params: params_data

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data']).to eq(cart_result)
      end
    end

    context 'when adding three quantity of strawberries product to the cart' do
      let(:charged_price) { 13.5 }
      let(:code) { 'SR1' }
      let(:has_promo) { true }
      let(:param_quantity) { 3 }
      let(:price) { 4.5 }
      let(:product_name) { 'Strawberries' }
      let(:quantity) { 3 }
      let(:total_price) { charged_price }

      it 'returns a JSON response with the price cut promo details' do
        post '/products/add_to_cart', params: params_data

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data']).to eq(cart_result)
      end
    end

    context 'when adding an invalid quantity' do
      let(:param_quantity) { -1 }
      let(:error_message) { 'Quantity must be greater than zero.' }

      it 'returns an error if the quantity is invalid' do
        post '/products/add_to_cart', params: params_data

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq(error_message)
      end
    end

    context 'when adding an invalid product' do
      let(:product) { nil }

      it 'returns an error if the product does not exist' do
        post '/products/add_to_cart', params: params_data

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Product not found')
      end
    end
  end
end
