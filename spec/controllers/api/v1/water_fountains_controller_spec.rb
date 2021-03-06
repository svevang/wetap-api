require 'spec_helper'

describe Api::V1::WaterFountainsController do
  render_views

  let(:valid_attributes) { { "location" => {"type" => "Point","coordinates" => [1.0,1.0]}, "working" => true, "dog_bowl" => false, "filling_station" => true, "flow" => "good" } }
  let(:valid_attributes_with_image) do
    valid_attributes.merge({ "image" => Base64.encode64(File.read(Rails.root + 'spec/fixtures/example_water_fountain.jpg')) })
  end
  let(:private_attribute_names) { ["data_source", "data_source_id", "import_source"] }
  let!(:user) { FactoryGirl.create(:user) }
  let!(:admin_user) { FactoryGirl.create(:admin_user) }
  let(:public_token) { admin_user.public_token }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # WaterFountainsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET index" do
    it "assigns all water_fountains as @water_fountains" do
      water_fountain = WaterFountain.create! valid_attributes
      get :index, {format: 'json'}, valid_session
      expect(assigns(:water_fountains)).to eq([water_fountain])
    end
    it "queries water fountains bounded_by bbox params" do
      expect(WaterFountain).to receive(:bounded_by)
      get :index, {format: 'json', bbox: '1,1,1,1'}, valid_session
      expect(response.status).to eq(200)
    end

    describe "#sanitize_bbox_params" do

      before do
        get :index, {format: 'json', bbox: bbox_params}, valid_session
      end

      subject { WaterFountain.bounding_box_from(params) }
      context "when sending too many params" do
        let(:bbox_params) { "1,1,1,1,1" }
        it { expect(response.status).to eq(400) }
      end
      context "when not sending enough params" do
        let(:bbox_params) { "1,1,1" }
        it { expect(response.status).to eq(400) }
      end
      context "when sending mangled params" do
        let(:bbox_params) { "select * from foo;" }
        it { expect(response.status).to eq(400) }
      end
      context "when sending the correct number of params" do
        let(:bbox_params) { "1,1,1,1" }
        it { expect(response.status).to eq(200) }
      end
    end

  end

  describe "GET show" do
    it "assigns the requested water_fountain as @water_fountain" do
      new_water_fountain = WaterFountain.create! valid_attributes
      get :show, {format: 'json', :id => new_water_fountain.to_param}, valid_session
      expect(assigns(:water_fountain)).to eq(new_water_fountain)

      water_fountain = assigns(:water_fountain)
      expected_response = {
        id: water_fountain.id,
        created_at: water_fountain.created_at,
        updated_at: water_fountain.updated_at,
        location: {
          type: "Point",
          coordinates: [1.0, 1.0]
        },
        image_url: nil,
        working: true,
        filling_station: true,
        dog_bowl: false,
        flow: "good",
        user_id: nil,
        user_name: "unknown",
        url: "http://test.host/api/v1/water_fountains/#{water_fountain.id}.json"
      }

      # Comparing dictionaries allows us to see which fields are mismatchd
      # when this test fails
      expect(JSON.parse(response.body)).to eq(JSON.parse(expected_response.to_json))
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new WaterFountain" do
        expect {
          post :create, {format: 'json', public_token: public_token, :water_fountain => valid_attributes}, valid_session
        }.to change(WaterFountain, :count).by(1)
      end

      it "assigns a newly created water_fountain as @water_fountain" do
        post :create, {format: 'json', public_token: public_token, :water_fountain => valid_attributes}, valid_session
        water_fountain = assigns(:water_fountain)
        expect(water_fountain).to be_a(WaterFountain)
        expect(water_fountain).to be_persisted
      end

      it "is possible to include an image" do
        WaterFountain.should_receive(:generate_image_filename).and_return("my-image-file.jpg")
        VCR.use_cassette('upload_fountain_image_to_s3', match_requests_on: [:method]) do
          post :create, {format: 'json', public_token: public_token, :water_fountain => valid_attributes_with_image}, valid_session
        end

        water_fountain = assigns(:water_fountain)
        expect(water_fountain).to be_a(WaterFountain)
        expect(water_fountain).to be_persisted

        expected_response = {
          id: water_fountain.id,
          created_at: water_fountain.created_at,
          updated_at: water_fountain.updated_at,
          user_id: water_fountain.user_id,
          user_name: water_fountain.user.email,
          working: true,
          filling_station: true,
          dog_bowl: false,
          flow: "good",
          location: {
            type: "Point",
            coordinates: [1.0, 1.0]
          },
          url: "http://test.host/api/v1/water_fountains/#{water_fountain.id}.json"
        }
        response_body = JSON.parse(response.body)

        # We have to test the image_url separately, because it is more complex than an equivalency
        image_url = response_body.delete("image_url")
        image_url.should match(/s3.*amazonaws\.com.*water_fountains\/images.*my-image-file\.jpg/)

        expect(response_body).to eq(JSON.parse(expected_response.to_json))
      end
    end


    describe "with invalid params" do
      it "assigns a newly created but unsaved water_fountain as @water_fountain" do
        # Trigger the behavior that occurs when invalid params are submitted
        post :create, {format: 'json', public_token: public_token, :water_fountain => { "location" => "invalid value" }}, valid_session
        expect(assigns(:water_fountain)).to be_a_new(WaterFountain)
      end

      it "returns an error" do
        # Trigger the behavior that occurs when invalid params are submitted
        post :create, {format: 'json', public_token: public_token, :water_fountain => { "location" => "invalid value" }}, valid_session
        expect(response.code).to eq("422")
        expect(JSON.parse(response.body)['error']).not_to be_empty
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested water_fountain" do
        water_fountain = WaterFountain.create! valid_attributes
        # Assuming there are no other water_fountains in the database, this
        # specifies that the WaterFountain created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.

        # see the WaterFountain's #location getter and setter to see why this is nil here
        expect_any_instance_of(WaterFountain).to receive(:update).with({ "location" => nil })
        put :update, {format: 'json', public_token: public_token, :id => water_fountain.to_param, :water_fountain => { "location" => "" }}, valid_session
      end

      it "assigns the requested water_fountain as @water_fountain" do
        water_fountain = WaterFountain.create! valid_attributes
        put :update, {format: 'json', public_token: public_token, :id => water_fountain.to_param, :water_fountain => valid_attributes}, valid_session
        expect(assigns(:water_fountain)).to eq(water_fountain)
      end

      it "responds with success/no body" do
        water_fountain = WaterFountain.create! valid_attributes
        put :update, {format: 'json', public_token: public_token, :id => water_fountain.to_param, :water_fountain => valid_attributes}, valid_session
        expect(response.code).to eq("204")
      end
    end

    describe "with invalid params" do
      it "assigns the water_fountain as @water_fountain" do
        water_fountain = WaterFountain.create! valid_attributes
        put :update, {format: 'json', public_token: public_token, :id => water_fountain.to_param, :water_fountain => { "location" => "invalid value" }}, valid_session

        expect(assigns(:water_fountain)).to eq(water_fountain)
      end

      it "should render validation errors JSON" do
        water_fountain = WaterFountain.create! valid_attributes
        put :update, {format: 'json', public_token: public_token, :id => water_fountain.to_param, :water_fountain => { "location" => "invalid value" }}, valid_session

        expect(response.code).to eq("422")
        expect(JSON.parse(response.body)['error']).not_to be_empty
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested water_fountain" do
      water_fountain = WaterFountain.create! valid_attributes
      expect {
        delete :destroy, {format: 'json', public_token: public_token, :id => water_fountain.to_param}, valid_session
      }.to change(WaterFountain, :count).by(-1)
    end

    it "responds with success/no body" do
      water_fountain = WaterFountain.create! valid_attributes
      delete :destroy, {format: 'json', public_token: public_token, :id => water_fountain.to_param}, valid_session
      expect(response.code).to eq("204")
    end
  end

  describe "authorizations" do
    subject { response.code }
    let(:water_fountain) { FactoryGirl.create(:water_fountain) }

    describe "GET index" do
      before { get :index, format: 'json', public_token: public_token }
      context "with user public_token" do
        let(:public_token) { user.public_token }
        it { should eq("200") }
      end
      context "with admin public_token" do
        let(:public_token) { admin_user.public_token }
        it { should eq("200") }
      end
      context "without any public_token" do
        let(:public_token) { nil }
        it { should eq("200") }
      end
    end
    describe "GET show" do
      before { get :show, format: 'json', id: water_fountain.to_param, public_token: public_token }
      context "with user public_token" do
        let(:public_token) { user.public_token }
        it { should eq("200") }
      end
      context "with admin public_token" do
        let(:public_token) { admin_user.public_token }
        it { should eq("200") }
      end
      context "without any public_token" do
        let(:public_token) { nil }
        it { should eq("200") }
      end
    end
    describe "POST create" do
      before { post :create, format: 'json', public_token: public_token, water_fountain: valid_attributes }
      context "with user public_token" do
        let(:public_token) { user.public_token }
        it { should eq("201") }
      end
      context "with admin public_token" do
        let(:public_token) { admin_user.public_token }
        it { should eq("201") }
      end
      context "without any public_token" do
        let(:public_token) { nil }
        it { should eq("401") }
      end
    end
    describe "PUT update" do
      before { put :update, format: 'json', public_token: public_token, id: water_fountain.to_param, water_fountain: valid_attributes }
      context "with user public_token" do
        let(:public_token) { user.public_token }
        it { should eq("403") }
      end
      context "with admin public_token" do
        let(:public_token) { admin_user.public_token }
        it { should eq("204") }
      end
      context "without any public_token" do
        let(:public_token) { nil }
        it { should eq("401") }
      end
    end
    describe "DELETE destroy" do
      before { delete :destroy, format: 'json', public_token: public_token, id: water_fountain.to_param }
      context "with user public_token" do
        let(:public_token) { user.public_token }
        it { should eq("403") }
      end
      context "with admin public_token" do
        let(:public_token) { admin_user.public_token }
        it { should eq("204") }
      end
      context "without any public_token" do
        let(:public_token) { nil }
        it { should eq("401") }
      end
    end
  end

end
