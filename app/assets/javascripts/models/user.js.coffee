App.User = DS.Model.extend
  entries:  hasMany "entry"
  
  email:  attr "string"