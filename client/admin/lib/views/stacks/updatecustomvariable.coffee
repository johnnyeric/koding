remote = require('app/remote').getInstance()


setStackTemplateCredential = (options, callback) ->

  { stackTemplate, credential } = options
  { credentials }    = stackTemplate
  credentials.custom = [credential.identifier]

  stackTemplate.update { credentials }, (err) ->
    callback err, stackTemplate


createAndUpdate = (options, callback) ->

  { provider, title, meta, stackTemplate } = options
  { JCredential } = remote.api

  JCredential.create { provider, title, meta }, (err, credential) ->
    return callback err  if err

    setStackTemplateCredential {
      stackTemplate, credential
    }, callback


module.exports = updateCustomVariable = (options, callback) ->

  { JCredential }         = remote.api
  { stackTemplate, meta } = options

  # TODO add multiple custom credential support if needed ~ GG
  identifier = stackTemplate.credentials.custom?.first
  title      = "Custom variables for #{stackTemplate.title}"
  provider   = 'custom'

  if identifier

    JCredential.one identifier, (err, credential) ->
      if err or not credential
        createAndUpdate { provider, title, meta, stackTemplate }, callback
      else
        credential.update { meta, title }, (err) ->
          callback err, stackTemplate

  else
    createAndUpdate { provider, title, meta, stackTemplate }, callback