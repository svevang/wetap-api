require 'spec_helper'

describe ApplicationController do

  describe "#after_sign_in_path_for" do
    subject { controller.after_sign_in_path_for(user) }

    context "when admin users are signing in" do
      let(:user){ User.new({admin: true}) }
      it { should eq(admin_path) }
    end

    context 'when regular users are signing in' do
      let(:user){ User.new }
      it { should eq(api_v1_water_fountains_after_login_path) }
    end
  end
end
