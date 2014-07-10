require 'spec_helper'

describe "WaterFountains" do
  describe "GET /water_fountains.json" do
    it "should return 200" do
      get api_v1_water_fountains_path(format: :json)
      expect(response.status).to be(200)
    end
  end

  describe "when supplying a token" do

    let!(:user) { User.create(email: "test@foo.com", password:"12345678") }
    let(:public_token) { user.public_token }
    let(:valid_attributes) { { "location" => {"type" => "Point","coordinates" => [1.0,1.0]} } }

    it "signs in a user for only one request" do
      post api_v1_water_fountains_path(format: :json, public_token: public_token, water_fountain: valid_attributes)
      expect(response.status).to be(201)
      post api_v1_water_fountains_path(format: :json, water_fountain: valid_attributes)
      expect(response.status).to be(401)
    end
  end

end
