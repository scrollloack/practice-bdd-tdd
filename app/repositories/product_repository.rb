class ProductRepository
  def self.model
    Product
  end

  def self.get_list
    model.all
  end
end
