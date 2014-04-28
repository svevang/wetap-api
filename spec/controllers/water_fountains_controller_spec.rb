require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe WaterFountainsController do
  render_views

  # This should return the minimal set of attributes required to create a valid
  # WaterFountain. As you add validations to WaterFountain, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { { "location" => {"type" => "Point","coordinates" => [1.0,1.0]} } }
  let(:private_attribute_names) { ["data_source", "data_source_id", "import_source"] }

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
        #get :index, {format: 'json', bbox: bbox_params}, valid_session
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
      water_fountain = WaterFountain.create! valid_attributes
      get :show, {format: 'json', :id => water_fountain.to_param}, valid_session
      expect(assigns(:water_fountain)).to eq(water_fountain)
      expect(response.body).to eq(assigns(:water_fountain).as_json.except(*private_attribute_names).to_json)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new WaterFountain" do
        expect {
          post :create, {format: 'json', :water_fountain => valid_attributes}, valid_session
        }.to change(WaterFountain, :count).by(1)
      end

      it "assigns a newly created water_fountain as @water_fountain" do
        post :create, {format: 'json', :water_fountain => valid_attributes}, valid_session
        expect(assigns(:water_fountain)).to be_a(WaterFountain)
        expect(assigns(:water_fountain)).to be_persisted
        expect(response.body).to eq(assigns(:water_fountain).as_json.except(*private_attribute_names).to_json)
      end

    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved water_fountain as @water_fountain" do
        # Trigger the behavior that occurs when invalid params are submitted
        post :create, {format: 'json', :water_fountain => { "location" => "invalid value" }}, valid_session
        expect(assigns(:water_fountain)).to be_a_new(WaterFountain)
      end

      it "returns an error" do
        # Trigger the behavior that occurs when invalid params are submitted
        post :create, {format: 'json', :water_fountain => { "location" => "invalid value" }}, valid_session
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
        put :update, {format: 'json', :id => water_fountain.to_param, :water_fountain => { "location" => "" }}, valid_session
      end

      it "assigns the requested water_fountain as @water_fountain" do
        water_fountain = WaterFountain.create! valid_attributes
        put :update, {format: 'json', :id => water_fountain.to_param, :water_fountain => valid_attributes}, valid_session
        expect(assigns(:water_fountain)).to eq(water_fountain)
      end

      it "responds with success/no body" do
        water_fountain = WaterFountain.create! valid_attributes
        put :update, {format: 'json', :id => water_fountain.to_param, :water_fountain => valid_attributes}, valid_session
        expect(response.code).to eq("204")
      end
    end

    describe "with invalid params" do
      it "assigns the water_fountain as @water_fountain" do
        water_fountain = WaterFountain.create! valid_attributes
        put :update, {format: 'json', :id => water_fountain.to_param, :water_fountain => { "location" => "invalid value" }}, valid_session

        expect(assigns(:water_fountain)).to eq(water_fountain)
      end

      it "should render validation errors JSON" do
        water_fountain = WaterFountain.create! valid_attributes
        put :update, {format: 'json', :id => water_fountain.to_param, :water_fountain => { "location" => "invalid value" }}, valid_session

        expect(response.code).to eq("422")
        expect(JSON.parse(response.body)['error']).not_to be_empty
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested water_fountain" do
      water_fountain = WaterFountain.create! valid_attributes
      expect {
        delete :destroy, {format: 'json', :id => water_fountain.to_param}, valid_session
      }.to change(WaterFountain, :count).by(-1)
    end

    it "responds with success/no body" do
      water_fountain = WaterFountain.create! valid_attributes
      delete :destroy, {format: 'json', :id => water_fountain.to_param}, valid_session
      expect(response.code).to eq("204")
    end
  end

end
