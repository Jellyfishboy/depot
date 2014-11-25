# Sku Documentation
#
# The Sku table manages all the product variations. 

# == Schema Information
#
# Table name: skus
#
#  id                         :integer          not null, primary key
#  code                       :string(255)      
#  length                     :decimal          precision(8), scale(2) 
#  weight                     :decimal          precision(8), scale(2) 
#  thickness                  :decimal          precision(8), scale(2) 
#  stock                      :integer 
#  stock_warning_level        :integer 
#  cost_value                 :decimal          precision(8), scale(2) 
#  price                      :decimal          precision(8), scale(2) 
#  product_id                 :integer 
#  active                     :boolean          default(true)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
class Sku < ActiveRecord::Base
  
  attr_accessible :cost_value, :price, :code, :stock, :stock_warning_level, :length, 
  :weight, :thickness, :product_id, :accessory_id, :active
  
  has_many :cart_items
  has_many :carts,                                                    through: :cart_items
  has_many :order_items,                                              dependent: :restrict_with_exception
  has_many :orders,                                                   through: :order_items, dependent: :restrict_with_exception
  has_many :notifications,                                            as: :notifiable, dependent: :delete_all
  has_many :stock_adjustments,                                        dependent: :delete_all
  has_one :category,                                                  through: :product
  belongs_to :product,                                                inverse_of: :skus
  has_many :variants,                                                 dependent: :delete_all, class_name: 'SkuVariant'
  has_many :variant_types,                                            -> { uniq }, through: :variants

  validates :price, :cost_value, :length, 
  :weight, :thickness, :code,                                         presence: true
  validates :price, :cost_value,                                      format: { with: /\A(\$)?(\d+)(\.|,)?\d{0,2}?\z/ }
  validates :length, :weight, :thickness,                             numericality: { greater_than_or_equal_to: 0 }
  validates :stock, :stock_warning_level,                             presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, :if => :new_record?
  validate :stock_values,                                             on: :create
  validates :code,                                                    uniqueness: { scope: [:product_id, :active] }

  after_update :update_cart_items_weight

  after_create :create_stock_adjustment

  # default_scope { order(code: :asc) }

  include ActiveScope

  # Validation check to ensure the stock value is higher than the stock warning level value when creating a new SKU
  #
  # @return [Boolean]
  def stock_values
    if self.stock && self.stock_warning_level && self.stock <= self.stock_warning_level
      errors.add(:sku, "stock warning level value must not be below your stock count.")
      return false
    end
  end

  # If the record's weight has changed, update all associated cart_items records with the new weight
  #
  def update_cart_items_weight
    cart_items = CartItem.where(sku_id: id)
    cart_items.each do |item|
      item.update_column(:weight, (weight*item.quantity))
    end
  end

  # Current stock for a SKU is the latest stock adjustment record
  # Which is related to the SKU
  #
  # @return [Integer] Stock value
  def stock_total
    stock_adjustments.empty? ? stock : stock_adjustments.first.stock_total
  end

  # Joins the parent product SKU and the current SKU with a hyphen
  #
  # @return [String] product SKU and current SKU concatenated
  def full_sku
    [product.sku, code].join('-')
  end

  # After creating a SKU record, also create a stock level record which logs the intiial stock value
  #
  def create_stock_adjustment
    StockAdjustment.create(description: 'Initial stock', adjustment: stock, sku_id: id, stock_total: stock)
  end
end
