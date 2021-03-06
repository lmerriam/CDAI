require "spec_helper"

describe V1::SymptomsController, type: :controller do

  let(:user) { create :user }

  before(:each) do
    sign_in(user)
    @request.env["HTTP_ACCEPT"] = "application/json"
  end

  context "CREATE" do

    it "creates a symptom if it doesn't already exist" do
      expect(Symptom.count).to eql 0
      post :create, {name: "droopy lips"}
      expect(Symptom.count).to eql 1
    end

    it "adds the symptom to the user, adds to symptom_count" do
      post :create, {name: "droopy lips"}

      expect(user.reload.symptoms_count).to eql 1
      expect(user.symptoms.first.name).to eql "droopy lips"
    end

    it "returns activated symptom" do
      symptoms = [
        {name: "fat toes"},
        {name: "slippery tongue"}
      ]

      symptoms.each do |symptom_attrs|
        symptom = create :symptom, symptom_attrs
        user.user_symptoms.activate symptom
      end

      post :create, {name: "droopy lips"}

      expect(response.body).to be_json_eql({symptom: {id: 1, name: "droopy lips"}}.to_json)
    end

    it "doesn't add existing symptom to user twice" do
      symptom = create :symptom, {name: "droopy lips"}
      user.user_symptoms.activate symptom
      expect(user.reload.active_symptoms.length).to eql 1

      post :create, {name: "droopy lips"}

      expect(user.reload.symptoms.length).to eql 1
      expect(user.active_symptoms.length).to eql 1
    end

    it "doesn't create symptom if it already exists" do
      create :symptom, {name: "droopy lips"}
      expect(Symptom.first.name).to eql "droopy lips"
      expect(Symptom.count).to eql 1

      post :create, name: "droopy lips"
      expect(Symptom.count).to eql 1
    end

    it "does not allow name exceeding fifty characters" do
      post :create, {name: "Lorem ipsum dolor sit amet consectetur adipisicing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua Ut enim ad minim veniam quis"}
      returns_groovy_error(model_name: "symptom", fields: [["name", "100_char_max_length"]], code: 400)
    end

    it "only allows alphanumeric and spaces in name" do
      post :create, name: "hi()$%^&"
      returns_groovy_error(model_name: "symptom", fields: [["name", "only_alphanumeric_hyphens_and_spaces"]], code: 400)
    end

    it "does not allow names with obscene words" do
      post :create, name: "fuck this shit"
      returns_groovy_error(model_name: "symptom", fields: [["name", "no_obscenities"]], code: 400)
    end

  end

  context "SEARCH" do
    let(:other_user) { create :user }

    before(:each) do
      user.user_symptoms.activate create(:symptom, name: "droopy lips")
      user.user_symptoms.activate create(:symptom, name: "droopiness")
      other_user.user_symptoms.activate Symptom.find_by(name: "droopy lips")
      other_user.user_symptoms.activate Symptom.find_by(name: "droopiness")
    end

    it "returns an array of results" do
      get :search, name: "droop"
      expect(json_response).to be_an Array
      expect(json_response.first).to be_a Hash
      expect(json_response.count).to eql 2
      expect(json_response.first["name"]).to eql "droopiness"
      expect(json_response.first["count"]).to eql 2
    end

  end

  context "DESTROY" do
    it "removes the symptom from actives, but keeps it in user.symptoms" do
      symptom = create :symptom, {name: "droopy lips"}
      user.user_symptoms.activate symptom

      delete :destroy, {id: symptom.id}

      returns_success(204)

      expect(user.reload.active_symptoms).to be_empty
      expect(user.symptoms.first.name).to eql "droopy lips"
    end

    it "returns 404 if not found" do
      delete :destroy, {id: 999}

      returns_groovy_error(name: "404")
    end
  end
end
