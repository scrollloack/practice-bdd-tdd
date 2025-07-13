class ProductsController < ApplicationController
  def index
    @products = GetProductsService.new.call

    render json: { 'data': @products }, status: 200
  end
end
