def setup_cdai_questions
  q=Question.create(name: "ab_pain", catalog: "cdai", kind: "select", section: 1, group: nil)
  QuestionInput.create({question_id: q.id, value: 0, label: "none", meta_label: "", helper: nil})
  QuestionInput.create({question_id: q.id, value: 1, label: "mild", meta_label: "", helper: nil})
  QuestionInput.create({question_id: q.id, value: 2, label: "moderate", meta_label: "", helper: nil})
  QuestionInput.create({question_id: q.id, value: 3, label: "severe", meta_label: "", helper: nil})

  q=Question.create(name: "general", catalog: "cdai", kind: "select", section: 2, group: nil)
  QuestionInput.create({question_id: q.id, value: 0, label: "well", meta_label: "", helper: nil})
  QuestionInput.create({question_id: q.id, value: 1, label: "below_par", meta_label: "", helper: nil})
  QuestionInput.create({question_id: q.id, value: 2, label: "poor", meta_label: "", helper: nil})
  QuestionInput.create({question_id: q.id, value: 3, label: "very_poor", meta_label: "", helper: nil})
  QuestionInput.create({question_id: q.id, value: 4, label: "terrible", meta_label: "", helper: nil})

  q=Question.create(name: "mass", catalog: "cdai", kind: "select", section: 3, group: nil)
  QuestionInput.create({question_id: q.id, value: 0, label: "none", meta_label: nil, helper: nil})
  QuestionInput.create({question_id: q.id, value: 3, label: "questionable", meta_label: nil, helper: nil})
  QuestionInput.create({question_id: q.id, value: 5, label: "present", meta_label: nil, helper: nil})

  q=Question.create(name: "stools", catalog: "cdai", kind: "number", section: 4, group: nil)
  QuestionInput.create({question_id: q.id, value: 0, label: nil, meta_label: nil, helper: "stools_daily"})

  q=Question.create(name: "hematocrit", catalog: "cdai", kind: "number", section: 5, group: nil)
  QuestionInput.create({question_id: q.id, value: 0, label: nil, meta_label: nil, helper: "hematocrit_without_decimal"})

  q=Question.create(name: "weight_current", catalog: "cdai", kind: "number", section: 6, group: nil)
  QuestionInput.create({question_id: q.id, value: 0, label: nil, meta_label: nil, helper: "current_weight"})

  q=Question.create(name: "weight_typical", catalog: "cdai", kind: "number", section: 7, group: nil)
  QuestionInput.create({question_id: q.id, value: 0, label: nil, meta_label: nil, helper: "typical_weight"})

  Question.create(name: "opiates",                    catalog: "cdai", kind: "checkbox", section: 8, group: "complications")
  Question.create(name: "complication_arthritis",     catalog: "cdai", kind: "checkbox", section: 8, group: "complications")
  Question.create(name: "complication_iritis",        catalog: "cdai", kind: "checkbox", section: 8, group: "complications")
  Question.create(name: "complication_erythema",      catalog: "cdai", kind: "checkbox", section: 8, group: "complications")
  Question.create(name: "complication_fever",         catalog: "cdai", kind: "checkbox", section: 8, group: "complications")
  Question.create(name: "complication_fistula",       catalog: "cdai", kind: "checkbox", section: 8, group: "complications")
  Question.create(name: "complication_other_fistula", catalog: "cdai", kind: "checkbox", section: 8, group: "complications")
end

def api_credentials(user)
  {user_email: user.email, user_token: user.authentication_token}
end
def invalid_credentials(user)
  {user_email: user.email, user_token: "nogood"}
end
def data_is_json
  {'CONTENT_TYPE' => "application/json", 'ACCEPT' => 'application/json'}
end
def login_with_user(user=nil)
  user ||= create :user
  post "/users/sign_in.json", api_credentials(user)
  return user
end

def expect_not_authenticated
  expect(parse_json(response.body)["error"]).to eq "You need to sign in or sign up before continuing."
  returns_code 401
end

# JSON RSpec stuff
def expect_json_is_empty(body)
  expect(body).to be_json_eql ""
end

def returns_code(code)
  expect(response.status).to eq code
end
def returns_success(code=false)
  expect(json_response["success"]).to eql true

  if code
    expect(response.status).to eq code
    returns_code(code)
  else
    expect(response.status).to match /2\d\d/
  end
end

def returns_groovy_error(name: false, code: false, fields: [], model_name: false)
  error = Hashie::Mash.new(json_response["errors"])
  if name
    if error.kind == "generic"
      expect(error.description).to eq "nice_errors.#{name}"
    else
      expect(error.title).to eq name
      expect(error.description).to eq "#{name}_description"
    end
  end

  fields.each do |field|
    if model_name
      expect(error.fields[model_name][field[0]].first.message).to eql field[1]
    else
      expect(error.fields[field[0]].first.message).to eql field[1]
    end
  end

  if fields.present?
    expect(error.kind).to eql "inline"
  else
    expect(error.kind).to match /general|generic/
  end

  expect(error.success).to eq false
  if code
    expect(error.code).to eql code
    returns_code(code)
  else
    expect(error.code.to_s).to match /[45]\d\d/
  end
end

def json_response
  parse_json(response.body)
end