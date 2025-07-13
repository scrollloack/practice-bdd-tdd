require 'rails_helper'

RSpec.describe GetProductsService do
  describe '#call' do
    let(:products) { build_stubbed_list(:product, 3) }

    subject(:service) { described_class.new }

    before { allow(ProductRepository).to receive(:get_list).and_return(products) }

    context 'when products exist' do
      it 'returns a list of products' do
        expect(service.call).to eq(products)
      end
    end

    context 'when no products exist' do
      let(:products) { [] }

      it 'returns an empty array' do
        expect(service.call).to eq([])
      end
    end
  end
end
