require 'spec_helper'

describe EntryAuditing, :disabled => true do

  let(:target_date) { Date.parse("Aug-13-2014").to_datetime.beginning_of_day }
  let!(:user) { create :user, created_at: 10.years.ago }
  let!(:entry) { build :entry, user_id: user.id.to_s, date: target_date.to_date }

  before(:each) do
    date = target_date - 10.days

    # Do some version stuffs, setup a history
    Timecop.travel(date)            # now Aug 3
    # === #
    user.create_audit               # v1

    user.user_conditions.activate   create(:condition, name: "allergies")
    user.user_symptoms.activate     create(:symptom, name: "runny nose")
    user.user_symptoms.activate     create(:symptom, name: "itchy throat")
    user.create_audit               # v2

    Timecop.travel(date+1.days)     # now Aug 4
    # === #
    user.user_treatments.activate   create(:treatment, name: "loratadine")
    user.settings = user.settings.merge({
      :"treatment_loratadine_quantity" => 10.0,
      :"treatment_loratadine_unit" => "mg"
    })
    user.create_audit               # v3

    Timecop.travel(date+9.days)     # now Aug 12
    # === #
    user.user_conditions.activate   create(:condition,name: "back pain")
    user.user_treatments.activate   create(:treatment, name: "sinus rinse")
    user.settings = user.settings.merge({
      :"treatment_sinus rinse_quantity" => 1.0,
      :"treatment_sinus rinse_unit" => "bottle"
    })
    user.create_audit               # v4

    # --- Target Date for Entry --- #

    Timecop.travel(date+11.days)    # now Aug 14
    # === #
    user.user_conditions.activate   create(:condition,name: "ticklishness")
    user.user_conditions.deactivate Condition.find_by(name: "back pain")
    user.user_treatments.activate   create(:treatment, name: "advil")
    user.user_symptoms.deactivate   Symptom.find_by(name: "itchy throat")
    user.settings = user.settings.merge({
      :"treatment_advil_quantity" => 400.0,
      :"treatment_advil_unit" => "mg",
      :"treatment_sinus rinse_quantity" => 2.0,
      :"treatment_sinus rinse_unit" => "bottle"
    })
    user.create_audit               # v5

    Timecop.return
  end

  it "has 5 audit versions", versioning: true do
    expect(PaperTrail).to be_enabled
    expect(user.versions.count).to eql 5+1 # updates + v0 event
  end

  it "has various conditions/treatments/symptoms at different versions", versioning: true do

    entry = Entry.new(user_id: user.id, date: Date.parse("Aug-02-2014").to_datetime.end_of_day).setup_with_audit!
    expect(entry.conditions).to                                               be_empty
    expect(entry.treatments.map(&:name)).to                                   be_empty
    expect(entry.catalog_definitions[:symptoms].flatten.map{|s| s[:name]}).to be_empty

    entry = Entry.new(user_id: user.id, date: Date.parse("Aug-03-2014").to_datetime.end_of_day).setup_with_audit!
    expect(entry.conditions).to                                               eql %w( allergies )
    expect(entry.treatments.map(&:name)).to                                   be_empty
    expect(entry.catalog_definitions[:symptoms].flatten.map{|s| s[:name]}).to eql %w( runny\ nose itchy\ throat )

    entry = Entry.new(user_id: user.id, date: Date.parse("Aug-04-2014").to_datetime.end_of_day).setup_with_audit!
    expect(entry.conditions).to                                               eql %w( allergies )
    expect(entry.treatments.map(&:name)).to                                   eql %w( loratadine )
    expect(entry.catalog_definitions[:symptoms].flatten.map{|s| s[:name]}).to eql %w( runny\ nose itchy\ throat )

    entry = Entry.new(user_id: user.id, date: Date.parse("Aug-12-2014").to_datetime.end_of_day).setup_with_audit!
    expect(entry.conditions).to                                               eql %w( allergies back\ pain )
    expect(entry.treatments.map(&:name)).to                                   eql %w( loratadine sinus\ rinse )
    expect(entry.catalog_definitions[:symptoms].flatten.map{|s| s[:name]}).to eql %w( runny\ nose itchy\ throat )

    entry = Entry.new(user_id: user.id, date: Date.parse("Aug-14-2014").to_datetime.end_of_day).setup_with_audit!
    expect(entry.conditions).to                                               eql %w( allergies ticklishness )
    expect(entry.treatments.map(&:name)).to                                   eql %w( loratadine sinus\ rinse advil )
    expect(entry.catalog_definitions[:symptoms].flatten.map{|s| s[:name]}).to eql %w( runny\ nose )
  end

  describe "#applicable_audit" do
    it "gets the applicable audit version", versioning: true do
      audit = entry.applicable_audit # Get version closest (looking pastwards) to the target entry

      expect(audit.created_at.strftime("%b-%d-%Y")).to eql (target_date-1.day).strftime("%b-%d-%Y")
    end
  end

  describe "#symptoms_definition" do
    it "uses existing symptoms on Entry, not reified ones", versioning: true do
      entry = create :symptom_entry, date: Date.today, user: user
      expect(entry.symptoms_definition.length).to eql 3

      user.user_symptoms.activate create(:symptom, name: "buckteeth")

      expect(entry.symptoms_definition.length).to eql 3
    end
  end

  describe "#using_latest_audit?" do
    it "returns true if there are no future audits ahead of it", versioning: true do
      entry.date = Date.parse("Aug-15-2014").to_datetime.end_of_day
      expect(entry.using_latest_audit?).to be_true

      user.create_audit
      expect(entry.using_latest_audit?).to be_false
    end
    it "returns true if there is no applicable audit", versioning: false do
      entry.date = Date.today
      expect(entry.using_latest_audit?).to be_true
    end
    it "false if there are future audits", versioning: true do
      entry.date = Date.parse("Aug-12-2014").to_datetime.end_of_day
      expect(entry.using_latest_audit?).to be_false
    end
  end

  describe "#setup_with_audit!" do
    it "adds to the entry based on audit contents", versioning: true do
      entry.setup_with_audit!

      expect(entry).to be_an Entry
      expect(entry.conditions).to eql %w( allergies back\ pain )
      expect(entry.treatments.map(&:name)).to eql %w( loratadine sinus\ rinse )
      expect(entry.catalog_definitions[:symptoms].flatten.map{|s| s[:name]}).to eql %w( runny\ nose itchy\ throat )
    end

    it "pulls from User.settings to setup treatments" do
      entry.setup_with_audit!
      loratadine = entry.treatments.detect{|t| t["name"] == "loratadine"}

      expect(loratadine["quantity"]).to eql 10.0
      expect(loratadine["unit"]).to eql "mg"
    end

    it "matches latest version correctly", versioning: true do
      entry.date = Date.today
      entry.setup_with_audit!

      expect(entry.applicable_audit.created_at.strftime("%b-%d-%Y")).to eql (target_date+1.day).strftime("%b-%d-%Y")

      expect(entry.conditions).to eql %w( allergies ticklishness )
      expect(entry.treatments.map(&:name)).to eql %w( loratadine sinus\ rinse advil )
      expect(entry.catalog_definitions[:symptoms].flatten.map{|s| s[:name]}).to eql %w( runny\ nose )
    end
  end

  describe "#update_audit" do
    let(:blank_user) { create :user, created_at: 10.years.ago }
    let(:entry) { create :entry, user_id: blank_user.id.to_s, date: Date.today }

    it "creates a new audit when it differs from applicable_audit", versioning: true do
      versions_count = blank_user.versions.length

      entry.update_audit
      expect(blank_user.reload.versions.length).to eql versions_count

      entry.update_attributes({responses: [{name: "buckteeth", value: nil, catalog: "symptoms"}]})
      entry.update_audit
      expect(blank_user.reload.versions.length).to eql versions_count + 1
    end

    it "updates user settings based on incoming treatments", versioning: true do
      versions_count = blank_user.versions.length

      entry.update_audit
      expect(blank_user.reload.versions.length).to eql versions_count

      entry.update_attributes({responses: [{name: "buckteeth", value: nil, catalog: "symptoms"}]})
      entry.update_audit
      expect(blank_user.reload.versions.length).to eql versions_count + 1
    end

    it "only creates a new audit if it is today", versioning: true do
      versions_count = blank_user.versions.length
      entry.update_attributes({responses: [{name: "buckteeth", value: nil, catalog: "symptoms"}]})

      entry.update_attributes({date: Date.yesterday})
      entry.update_audit
      expect(blank_user.reload.versions.length).to eql versions_count
    end
  end

end
