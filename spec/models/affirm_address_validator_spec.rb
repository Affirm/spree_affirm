require 'spec_helper'

describe Affirm::AddressValidator do
  it 'detects when region1_code is missing' do
    input_addr = {
      state: 'California for example'
    }
    output = Affirm::AddressValidator.normalize_affirm_address(
      input_addr)
    expect(output['region1_code']).to eq(input_addr['state'])
  end
end

