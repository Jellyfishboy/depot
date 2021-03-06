require 'rails_helper'

describe AddressCountry do

    # ActiveRecord relations
    it { expect(subject).to belong_to(:address) }
    it { expect(subject).to belong_to(:country) }

    # Validations
    it { expect(create(:address_country)).to validate_presence_of(:country_id) }
    it { expect(create(:address_country)).to validate_uniqueness_of(:address_id).scoped_to(:country_id) }
end
