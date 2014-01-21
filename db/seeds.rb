# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Clear it out first
Entry.all.each{|e| e.destroy}
old_user=User.find_by_email("test@test.com")
old_user.delete if old_user
Question.delete_all

u=User.create(email: "test@test.com", password: "testing123", password_confirmation: "testing123", gender: "male", weight: 145)

Question.create(name: "ab_pain",        catalog: "cdai", kind: "select", section: 1, group: nil, options: [{value: 0, label: "none", meta_label: "happy_face", helper: nil}, {value: 1, label: "mild", meta_label: "neutral_face", helper: nil}, {value: 2, label: "moderate", meta_label: "frowny_face", helper: nil}, {value: 3, label: "severe", meta_label: "sad_face", helper: nil}])
Question.create(name: "general",        catalog: "cdai", kind: "select", section: 2, group: nil, options: [{value: 0, label: "well", meta_label: "happy_face", helper: nil}, {value: 1, label: "below_par", meta_label: "neutral_face", helper: nil}, {value: 2, label: "poor", meta_label: "frowny_face", helper: nil}, {value: 3, label: "very_poor", meta_label: "sad_face", helper: nil}, {value: 4, label: "terrible", meta_label: "terrible_face", helper: nil}])
Question.create(name: "mass",           catalog: "cdai", kind: "select", section: 3, group: nil, options: [{value: 0, label: "none", meta_label: "happy_face", helper: nil}, {value: 3, label: "questionable", meta_label: nil, helper: nil}, {value: 5, label: "present", meta_label: nil, helper: nil}])
Question.create(name: "stools",         catalog: "cdai", kind: "number", section: 4, group: nil, options: [{value: 0, label: nil, meta_label: nil, helper: "stools_weekly"}])
Question.create(name: "hematocrit",     catalog: "cdai", kind: "number", section: 5, group: nil, options: [{value: 0, label: nil, meta_label: nil, helper: "hematocrit_without_decimal"}])
Question.create(name: "weight_current", catalog: "cdai", kind: "number", section: 6, group: nil, options: [{value: 0, label: nil, meta_label: nil, helper: "current_weight"}])
Question.create(name: "weight_typical", catalog: "cdai", kind: "number", section: 7, group: nil, options: [{value: 0, label: nil, meta_label: nil, helper: "typical_weight"}])
Question.create(name: "opiates",                    catalog: "cdai", kind: "checkbox", section: 8, group: "complications", options: nil)
Question.create(name: "complication_arthritis",     catalog: "cdai", kind: "checkbox", section: 8, group: "complications", options: nil)
Question.create(name: "complication_iritis",        catalog: "cdai", kind: "checkbox", section: 8, group: "complications", options: nil)
Question.create(name: "complication_erythema",      catalog: "cdai", kind: "checkbox", section: 8, group: "complications", options: nil)
Question.create(name: "complication_fever",         catalog: "cdai", kind: "checkbox", section: 8, group: "complications", options: nil)
Question.create(name: "complication_fistula",       catalog: "cdai", kind: "checkbox", section: 8, group: "complications", options: nil)
Question.create(name: "complication_other_fistula", catalog: "cdai", kind: "checkbox", section: 8, group: "complications", options: nil)

Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 2}, {name: "ab_pain", value: 1}, {name: "general", value: 4}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: false}, {name: "complication_erythema", value: true}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: false}, {name: "mass", value: 2}, {name: "hematocrit", value: 40}, {name: "weight_current", value: 140}], date: Time.now-17.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 4}, {name: "ab_pain", value: 1}, {name: "general", value: 4}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: true}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: true}, {name: "mass", value: 5}, {name: "hematocrit", value: 50}, {name: "weight_current", value: 150}], date: Time.now-16.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 1}, {name: "ab_pain", value: 1}, {name: "general", value: 3}, {name: "complication_arthritis", value: false}, {name: "complication_iritis", value: false}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: false}, {name: "mass", value: 5}, {name: "hematocrit", value: 40}, {name: "weight_current", value: 140}], date: Time.now-15.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 2}, {name: "ab_pain", value: 2}, {name: "general", value: 4}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: false}, {name: "complication_erythema", value: true}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: true}, {name: "opiates",  value: true}, {name: "mass", value: 5}, {name: "hematocrit", value: 40}, {name: "weight_current", value: 130}], date: Time.now-14.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 2}, {name: "ab_pain", value: 2}, {name: "general", value: 4}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: false}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: false}, {name: "mass", value: 0}, {name: "hematocrit", value: 38}, {name: "weight_current", value: 140}], date: Time.now-13.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 3}, {name: "ab_pain", value: 1}, {name: "general", value: 4}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: true}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: true}, {name: "mass", value: 0}, {name: "hematocrit", value: 40}, {name: "weight_current", value: 140}], date: Time.now-12.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 2}, {name: "ab_pain", value: 2}, {name: "general", value: 3}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: false}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: false}, {name: "mass", value: 5}, {name: "hematocrit", value: 44}, {name: "weight_current", value: 110}], date: Time.now-11.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 3}, {name: "ab_pain", value: 3}, {name: "general", value: 2}, {name: "complication_arthritis", value: false}, {name: "complication_iritis", value: false}, {name: "complication_erythema", value: true}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: false}, {name: "mass", value: 2}, {name: "hematocrit", value: 43}, {name: "weight_current", value: 140}], date: Time.now-10.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 2}, {name: "ab_pain", value: 4}, {name: "general", value: 2}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: false}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: true}, {name: "mass", value: 5}, {name: "hematocrit", value: 42}, {name: "weight_current", value: 140}], date: Time.now-9.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 1}, {name: "ab_pain", value: 4}, {name: "general", value: 2}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: true}, {name: "complication_erythema", value: true}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: true}, {name: "opiates",  value: false}, {name: "mass", value: 2}, {name: "hematocrit", value: 40}, {name: "weight_current", value: 140}], date: Time.now-8.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 1}, {name: "ab_pain", value: 3}, {name: "general", value: 1}, {name: "complication_arthritis", value: false}, {name: "complication_iritis", value: false}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: false}, {name: "mass", value: 2}, {name: "hematocrit", value: 40}, {name: "weight_current", value: 120}], date: Time.now-7.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 2}, {name: "ab_pain", value: 2}, {name: "general", value: 1}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: true}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: false}, {name: "mass", value: 5}, {name: "hematocrit", value: 48}, {name: "weight_current", value: 140}], date: Time.now-6.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 2}, {name: "ab_pain", value: 3}, {name: "general", value: 1}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: false}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: false}, {name: "mass", value: 0}, {name: "hematocrit", value: 40}, {name: "weight_current", value: 150}], date: Time.now-5.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 4}, {name: "ab_pain", value: 1}, {name: "general", value: 1}, {name: "complication_arthritis", value: false}, {name: "complication_iritis", value: true}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: true}, {name: "mass", value: 5}, {name: "hematocrit", value: 56}, {name: "weight_current", value: 140}], date: Time.now-4.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 4}, {name: "ab_pain", value: 2}, {name: "general", value: 2}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: false}, {name: "complication_erythema", value: true}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: true}, {name: "opiates",  value: false}, {name: "mass", value: 5}, {name: "hematocrit", value: 40}, {name: "weight_current", value: 130}], date: Time.now-3.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 3}, {name: "ab_pain", value: 1}, {name: "general", value: 2}, {name: "complication_arthritis", value: false}, {name: "complication_iritis", value: false}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: false}, {name: "mass", value: 5}, {name: "hematocrit", value: 52}, {name: "weight_current", value: 140}], date: Time.now-2.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 2}, {name: "ab_pain", value: 1}, {name: "general", value: 4}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: true}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: false}, {name: "mass", value: 2}, {name: "hematocrit", value: 40}, {name: "weight_current", value: 140}], date: Time.now-1.day)
Entry.create(user: u, catalogs: ["cdai"], responses: [{name: "weight_typical", value: 140}, {name: "stools", value: 2}, {name: "ab_pain", value: 3}, {name: "general", value: 2}, {name: "complication_arthritis", value: true}, {name: "complication_iritis", value: false}, {name: "complication_erythema", value: false}, {name: "complication_fistula", value: false}, {name: "complication_fever", value: true}, {name: "complication_other_fistula", value: false}, {name: "opiates",  value: false}, {name: "mass", value: 5}, {name: "hematocrit", value: 40}, {name: "weight_current", value: 140}], date: Time.now)