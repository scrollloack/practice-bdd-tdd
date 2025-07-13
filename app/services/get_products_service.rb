class GetProductsService
  def call
    process
  end

  private

    def process
      ProductRepository.get_list
    end
end
