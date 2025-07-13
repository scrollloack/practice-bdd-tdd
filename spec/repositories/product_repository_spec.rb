require 'rails_helper'

RSpec.describe ProductRepository do
  subject { described_class }

  describe '.model' do
    it 'returns the Product model' do
      expect(subject.model).to eq(Product)
    end
  end

  describe '.get_list' do
    let(:products) { build_stubbed_list(:product, 3) }

    before { allow(Product).to receive(:all).and_return(products) }

    context 'when products exist' do
      it 'returns a list of products' do
        expect(subject.get_list).to match_array(products)
      end
    end

    context 'when no products exist' do
      let(:products) { [] }

      it 'returns an empty list' do
        expect(subject.get_list).to match_array(products)
      end
    end
  end
end
