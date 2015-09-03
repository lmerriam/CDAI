class Entry < CouchRest::Model::Base
  include ActiveModel::SerializerSupport
  include CatalogScore
  include SymptomsCatalog
  include ConditionsCatalog
  include TreatmentsCatalog
  include EntryAuditing
  include BasicQuestionTemplate

  AVAILABLE_CATALOGS = %w( hbi rapid3 phq9 )

  @queue = :entries

  def initialize(attributes={}, options={})
    super(attributes, options)
    include_catalogs
  end

  before_create :include_catalogs
  before_save   :include_catalogs
  before_save :set_treatment_repetitions

  after_save :process_responses
  after_save :enqueue

  belongs_to :user

  property :date,       Date
  property :settings,   Hash,     default: {}
  property :catalogs,   [String], default: []
  property :conditions, [String], default: []
  property :symptoms,   [String], default: []
  property :treatments, [EntryTreatment], default: []

  property :responses,  [Response], default: []
  property :notes,      String, default: ""
  property :tags,       [String], default: []

  property :scores,     [Score], default: []

  attr_accessor :user_audit_version

  timestamps!

  design do
    view :by_date
    view :by_user_id
    view :by_date_and_user_id
  end

  def user
    @user ||= User.find(user_id)
  end

  def catalog_definitions
    definition = base_definition
    definition[:symptoms]   = symptoms_definition
    definition[:conditions] = conditions_definition
    definition
  end

  # Collect all question names from included catalogs
  #
  # Returns array of question name symbols
  def question_names
    self.catalogs.reduce([]) do |names, catalog|
      questions = "#{catalog.capitalize}Catalog".constantize.const_get("QUESTIONS")
      namespaced_questions = questions.map{|question| "#{catalog}_#{question}".to_sym }

      names + namespaced_questions
    end
  end

  def complete?
    catalogs.each{|catalog| return false unless self.send("complete_#{catalog}_entry?")}
    true
  end

  ### RESPONSES PROCESSING ###
  def response_catalogs
    self.responses.map{|r| r[:catalog] }.uniq - ["symptoms", "conditions"]
  end

  def response_conditions
    # Don't use catalogs, not all conditions have them
    # self.response_catalogs.map{ |c| CATALOG_CONDITIONS.invert[c] }.compact
    responses.select{|r| r[:catalog] == "conditions"}.map(&:name).compact
  end

  def response_symptoms
    responses.select{|r| r[:catalog] == "symptoms"}.map(&:name).compact
  end


  def process_responses
    self.attributes = {
      catalogs:   response_catalogs,
      conditions: response_conditions,
      symptoms:   response_symptoms,
    }

    # process_notes
    process_tags

    treatment_settings = self.treatments.group_by(&:name).reduce({}) do |accum,(name,treatment_group)|

      treatment_group.each_with_index do |t,i|
        if t.quantity and t.unit
          accum["treatment_#{name}_#{i+1}_quantity"]  = t.quantity.to_s # as string for postgres comparison
          accum["treatment_#{name}_#{i+1}_unit"]      = t.unit.to_s
        end
      end

      accum
    end

    self.settings = settings.merge!(treatment_settings)
    save_without_processing
  end

  def enqueue
    Resque.enqueue(Entry, self.id)
  end

  def self.perform(entry_id, notify=true)
    entry = Entry.find(entry_id)

    (entry.catalogs | Globals::PSEUDO_CATALOGS).each do |catalog|
      entry.send("save_score", catalog)
      entry.save_without_processing
    end

    Resque.logger.info { ":::::::: Enqueuing Keen data collectiong for Entry" }
    Resque.enqueue_at(1.day.from_now, EntrySendToKeen, {id: entry.id, timestamp: Time.now.to_s})

    Resque.logger.info { ":::::::: Sending Pusher event for entry update" }
    entry.user.notify!("entry_processed", {entry_date: entry.date.strftime("%b-%d-%Y")}) #if entry.complete? and notify
    true
  end

  def save_without_processing
    Entry.skip_callback(:save, :after, :enqueue)
    Entry.skip_callback(:save, :after, :process_responses)
    save
    Entry.set_callback(:save, :after, :enqueue)
    Entry.set_callback(:save, :after, :process_responses)
  end

  private
  def process_tags
    self.user.tag_list.add(self.tags)
    self.user.save
  end

  # def process_notes
  #   self.tags = HashtagParser.new(self.notes).parse
  #   self.user.tag_list.add(self.tags)
  #   self.user.save
  # end

  def set_treatment_repetitions
    rep = 1
    self.treatments.sort_by(&:name).each.with_index do |treatment,i|
      rep = treatment.name == self.treatments.sort_by(&:name)[i-1].try(:name) ? rep+1 : 1
      self.treatments[i-1].repetition = rep
    end
  end

  def base_definition
    self.catalogs.reduce({}) do |definitions,catalog|
      _module = "#{catalog.capitalize}Catalog".constantize
      definitions[catalog.to_sym] = _module.const_get("DEFINITION")
      definitions
    end
  end

  def conditions_definition
    self.conditions.reduce([]) do |questions,condition|
      questions << basic_question(condition)

      questions
    end

  end

  def include_catalogs
    if catalogs.present?
      loadable_catalogs = catalogs.select{|catalog| AVAILABLE_CATALOGS.include?(catalog)}
      loadable_catalogs.each{|catalog| self.class_eval { include "#{catalog}_catalog".classify.constantize }}
    end
  end

  def method_missing(name, *args)

    # Lookup Score for any _score methods from included catalogs
    if match = name.to_s.match(/(\w+)_score\Z/)
      self.scores.detect{|s| s[:name] == match[1] }.value

    # Lookup Response.value base on {catalog}_{question_name} format
    elsif question_names.include?(name)
      catalog, question_name = name.to_s.match(/(\w+?)_(.*)\Z/).to_a[1..2]
      response = responses.detect{|r| r.catalog == catalog and r.name == question_name}

      return response.value if response
    else
      super(name, *args)
    end

  end

end
