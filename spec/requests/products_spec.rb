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
    let(:code) { 'some_product_code' }
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
        'quantity' => quantity
      }
    end
    let(:cart_result) do
      {
        'products' => cart_item,
        'total_price' => total_price,
        'total_quantity'=> total_quantity
      }
    end
    let(:params_data) do
      {
        'data': {
          'code': code,
          'quantity': quantity
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

    it 'returns a JSON response of the added product' do
      post '/products/add_to_cart', params: params_data

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['data']).to eq(cart_result)
    end
  end
end
