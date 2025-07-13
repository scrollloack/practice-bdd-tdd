require 'rails_helper'

RSpec.describe '/products', type: :request do
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
end
