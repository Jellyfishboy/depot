require 'spec_helper'

describe Accessory do

    # ActiveRecord relations
    it { expect(subject).to have_many(:cart_item_accessories) }
    it { expect(subject).to have_many(:cart_items).through(:cart_item_accessories) }
    it { expect(subject).to have_many(:carts).through(:cart_items) }
    it { expect(subject).to have_many(:order_item_accessories).dependent(:restrict) }
    it { expect(subject).to have_many(:order_items).through(:order_item_accessories).dependent(:restrict) }
    it { expect(subject).to have_many(:orders).through(:order_items) }
    it { expect(subject).to have_many(:accessorisations).dependent(:delete_all) }
    it { expect(subject).to have_many(:products).through(:accessorisations) }

    # Validations
    it { expect(subject).to validate_presence_of(:name) }
    it { expect(subject).to validate_presence_of(:part_number) }

    it { expect(subject).to validate_numericality_of(:part_number).only_integer } 
    it { expect(subject).to validate_numericality_of(:part_number).is_greater_than_or_equal_to(1) } 


    it { expect(subject).to validate_uniqueness_of(:name).scoped_to(:active) }
    it { expect(subject).to validate_uniqueness_of(:part_number).scoped_to(:active) }

    context "When a used accessory is updated or deleted" do

        it "should set the record as inactive" do
            accessory = create(:accessory)
            accessory.inactivate!
            expect(accessory.active).to eq false
        end
    end

    context "When the new accessory fails to update" do

        it "should set the record as active" do
            accessory = create(:accessory, active: false)
            accessory.activate!
            expect(accessory.active).to eq true
        end
    end

    it "should return an array of 'active' accessorys" do
        accessory_1 = create(:accessory)
        accessory_2 = create(:accessory, active: false)
        accessory_3 = create(:accessory)
        expect(Accessory.active).to match_array([accessory_1, accessory_3])
    end

end