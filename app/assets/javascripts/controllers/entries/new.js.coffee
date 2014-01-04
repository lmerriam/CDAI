App.EntriesNewController = Em.ObjectController.extend
  actions:
    save: ->
      that = @
      @get("model").save().then(
        (response) -> 
          that.set("model", that.store.createRecord("entry"))
          that.transitionToRoute("entries")
          
        (response) -> App.generalError(reason, "There was a problem with that entry, please make sure everything is filled out correctly.")
      )
  