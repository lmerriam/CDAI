require 'spec_helper'

module FooCatalog
  extend ActiveSupport::Concern

  DEFINITION = {
    general_wellbeing: [{
      name: :general_wellbeing,
      section: 0,
      kind: :select
    }]
  }
  QUESTIONS = DEFINITION.map{|k,v| v}.map{|questions| questions.map{|question| question[:name] }}.flatten
  included do |base_class|
    validate :response_ranges
    def response_ranges
      ranges = [
        [:general_wellbeing, [*99..101]]
      ]
    end
  end
end


describe Entry do
  let(:entry) { create :entry, conditions: ["Crohn's disease"] }

  describe "AVAILABLE_CATALOGS" do
    before(:each) do
      module FooCatalog; def bar; end; end
    end
    it "only accepts known catalogs" do
      entry.catalogs << "foo"
      entry.save
      expect(entry).to_not respond_to :bar

      stub_const("Entry::AVAILABLE_CATALOGS", ["foo"])
      expect(create :entry, catalogs: ["foo"]).to respond_to :bar
    end
  end

  describe "#complete?" do
    let(:entry) { create :hbi_entry }

    it "is complete when all it's catalogs (1 or more) are complete" do
      expect(entry).to be_complete
      entry.responses.first.delete
      expect(entry).to_not be_complete
    end
  end

  describe "initialization (using HBI module)" do
    let(:entry) { create :hbi_entry }
    before(:each) do
      with_resque{ entry.save }; entry.reload
    end

    # it "includes a constant for for catalog score components" do
    #   expect(Entry::SCORE_COMPONENTS).to include :stools
    # end
    it "responds to missing methods by checking if a Question of that name exists" do
      expect(entry.methods).to_not include :hbi_stools
      expect(entry.hbi_stools).to be_a Float
    end
    it "responds to missing methods by checking scores for a score in the format 'catalog'_score" do
      expect(entry.methods).to_not include :hbi_score
      expect(entry.hbi_score).to be_a Float
    end
    it "an actual missing method supers to method_missing" do
      expect{ entry.nosuchmethod }.to raise_error NoMethodError
    end
  end

  describe "Multiple Catalogs" do
    let(:entry) { create :entry }
    before(:each) do
      stub_const("Entry::AVAILABLE_CATALOGS", ["foo", "hbi"])
    end
    it "prepends question_names with the catalog they belong to" do
      entry.catalogs = ["foo", "hbi"]
      # respond_to? doesn't work with method_missing. Implementing respond_to? causes problems with CouchRest...
      expect{entry.foo_general_wellbeing}.not_to raise_error
      expect{entry.hbi_general_wellbeing}.not_to raise_error
    end
  end

  describe "Condition (Illness) Severity Questions" do
    let!(:entry) { create :entry}

    it "has a generic question for each condition in the catalog definition" do
      entry.conditions = ["Crohn's disease"]

      conditions = entry.catalog_definitions[:conditions]
      expect(conditions).to be_an Array
      expect(conditions.first).to be_an Array
      expect(conditions.first.first[:name]).to eql "Crohn's disease"
    end

    it "it works with multiple, they go into the same section" do
      entry.conditions = ["Allergies", "Crohn's disease"]

      conditions = entry.catalog_definitions[:conditions]
      expect(conditions.first.first[:name]).to eql "Allergies"
      expect(conditions.first.last[:name]).to eql "Allergies"
    end
  end

  describe "Response processing" do
    let(:responses_for_hbi) { [
        { catalog: "hbi", name: "general_wellbeing", value: 4 }
    ] }
    let(:responses_for_hbi_and_symptoms) { [
        { catalog: "hbi", name: "general_wellbeing", value: 4 },
        { catalog: "symptoms", name: "droopy lips", value: 3 },
        { catalog: "symptoms", name: "fat toes", value: 2 },
        { catalog: "conditions", name: "Crohn's disease", value: 2 },
    ] }
    let(:entry_settings) {
      {
        dobDay: "13",
        dobMonth: "08",
        dobYear: "1986",
        onboarded: "true",
        ethnicOrigin: "[\"Latino or Hispanic\"]"
      }
    }
    let(:treatment_responses) {
      { treatments: [
          {name: "Tickles", quantity: "1.0", unit: "session"},
          {name: "Tickles", quantity: "1.0", unit: "session"},
          {name: "Orange Juice", quantity: "1.0", unit: "l"},
        ]
      }
    }

    let(:entry) { create :entry }
    it "sets catalogs based on the responses" do
      expect(entry.catalogs).to eql []

      entry.responses = responses_for_hbi
      entry.process_responses
      expect(entry.catalogs).to eql ["hbi"]

      entry.responses = responses_for_hbi_and_symptoms
      entry.process_responses
      expect(entry.catalogs).to eql ["hbi"]

      entry.responses = []
      entry.process_responses
      expect(entry.catalogs).to eql []
    end

    it "sets conditions based on responses" do
      expect(entry.conditions).to eql []

      entry.responses = responses_for_hbi_and_symptoms
      entry.process_responses
      expect(entry.conditions).to eql ["Crohn's disease"]

      entry.responses = []
      entry.process_responses
      expect(entry.conditions).to eql []
    end

    it "sets symptoms based on responses" do
      expect(entry.symptoms).to eql []

      entry.responses = responses_for_hbi_and_symptoms
      entry.process_responses
      expect(entry.symptoms).to eql ["droopy lips", "fat toes"]

      entry.responses = []
      entry.process_responses
      expect(entry.symptoms).to eql []
    end

    # it "sets tags from notes on Entry and User" do
    #   expect(entry.tags).to eql []
    #
    #   entry.notes = "Some #crazy tagging stuff with#lamepants tags in the #middle"
    #   entry.process_responses
    #   expect(entry.tags).to eql ["crazy", "middle"]
    #   expect(entry.user.tag_list).to eql ["crazy", "middle"]
    #
    #   entry.notes = []
    #   entry.process_responses
    #   expect(entry.tags).to eql []
    # end

    context "Entry settings" do

      it "coerces some of the string settings into integers and such" do
        entry.update_attribute(:settings,entry_settings)
        expect(entry.settings[:dobDay]).to eql 13
        expect(entry.settings[:dobMonth]).to eql 8
        expect(entry.settings[:dobYear]).to eql 1986
        expect(entry.settings[:onboarded]).to be_true
        expect(entry.settings[:ethnicOrigin]).to eql ["Latino or Hispanic"]
      end

      it "for empty ethnicOrigin, just sets an empty array" do
        entry_settings.delete(:ethnicOrigin)
        entry.update_attribute(:settings, entry_settings)
        expect(entry.settings[:ethnicOrigin]).to eql []
      end

      it "new treatment settings replace old ones if present" do
        exercise = treatment_responses.deep_dup
        exercise[:treatments].concat [
          {name: "Exercise", quantity: "10.0", unit: "minute"},
          {name: "Exercise", quantity: "20.0", unit: "minute"},
        ]

        new_exercise = treatment_responses.deep_dup
        new_exercise[:treatments].concat [
          {name: "Exercise", quantity: "1.0", unit: "hour"}
        ]

        entry.update_attributes exercise
        entry.process_responses
        entry.update_audit

        expect(entry.settings["treatment_Tickles_1_quantity"]).to be_present
        expect(entry.settings["treatment_Exercise_1_quantity"]).to eql "10.0"
        expect(entry.settings["treatment_Exercise_1_unit"]).to eql "minute"
        expect(entry.settings["treatment_Exercise_2_quantity"]).to eql "20.0"
        expect(entry.user.settings["treatment_Exercise_2_quantity"]).to eql "20.0"

        entry.update_attributes new_exercise
        entry.process_responses
        entry.update_audit

        expect(entry.settings["treatment_Tickles_1_quantity"]).to be_present
        expect(entry.settings["treatment_Exercise_1_quantity"]).to eql "1.0"
        expect(entry.settings["treatment_Exercise_1_unit"]).to eql "hour"
        expect(entry.settings["treatment_Exercise_2_quantity"]).to eql nil
        expect(entry.user.settings["treatment_Exercise_2_quantity"]).to eql nil
      end

    end

    it "sets tags from the tags in response" do
      expect(entry.tags).to eql []

      entry.update_attributes tags: ["crazy", "banana", "banzai"]
      entry.process_responses
      expect(entry.tags).to eql ["crazy", "banana", "banzai"]
      expect(entry.user.tag_list).to eql ["crazy", "banana", "banzai"]
    end

    it "allows for mulitple treatments of the same name" do
      expect(entry.treatments).to eql []

      entry.update_attributes treatment_responses
      entry.process_responses
      expect(entry.treatments.map(&:name)).to match_array ["Tickles", "Tickles", "Orange Juice"]

      entry.responses = []
      entry.process_responses
      expect(entry.symptoms).to eql []
    end

  end

end