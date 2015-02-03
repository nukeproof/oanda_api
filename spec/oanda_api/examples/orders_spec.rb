require 'spec_helper'
require 'support/client_helper'

describe "OandaAPI::Resource::Order" do
  let(:account) { ClientHelper.account }
  let(:price)   { ClientHelper.instrument("EUR_USD").bid - 0.1 }

  it "creates an order", :vcr do
    VCR.use_cassette("account(id).order(options).create") do
      order = account.order(instrument: "EUR_USD",
                                  type: "market",
                                  side: "buy",
                                 units: 10_000)
                     .create
      expect(order).to be_an OandaAPI::Resource::Order
    end
  end

  it "gets all open orders", :vcr do
    VCR.use_cassette("account(id).orders.get") do
      ClientHelper.create_order(type: "limit", price: price)
      orders = account.orders.get
      expect(orders.first).to be_an OandaAPI::Resource::Order
    end
  end

  it "gets a filtered list of open orders", :vcr do
    VCR.use_cassette("account(id).orders(options).get") do
      ClientHelper.create_order(instrument: "USD_JPY", type: "limit", price: price)

      orders = account.orders(instrument: "USD_JPY").get
      expect(orders.first).to be_an OandaAPI::Resource::Order
    end
  end

  it "gets a specific open order", :vcr do
    VCR.use_cassette("account(id).order(id).get") do
      order_id = ClientHelper.create_order(type: "limit", price: price)
                             .order_opened
                             .id
      expect(account.order(order_id).get).to be_an OandaAPI::Resource::Order
    end
  end

  it "modifies an open order", :vcr do
    VCR.use_cassette("account(id).order(options).update") do
      order_id = ClientHelper.create_order(type: "limit", price: price)
                             .order_opened
                             .id
      updated_order = account.order(id: order_id, units: 9_000).update
      expect(updated_order.units).to eq 9_000
    end
  end

  it "closes an open order", :vcr do
    VCR.use_cassette("account(id).order(id).close") do
      order_id = ClientHelper.create_order(type: "limit", price: price)
                             .order_opened
                             .id
      before_order_ids = account.orders.get.map(&:id)
      account.order(order_id).close
      after_order_ids = account.orders.get.map(&:id)

      expect(before_order_ids).to include order_id
      expect(after_order_ids).not_to include order_id
    end
  end
end
