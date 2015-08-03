actions         = require '../actions/actiontypes'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/store'

module.exports = class SelectedMessageThreadIdStore extends KodingFluxStore

  @getterPath = 'SelectedMessageThreadIdStore'

  getInitialState: -> null

  initialize: ->

    @on actions.SET_SELECTED_MESSAGE_THREAD, @setSelectedMessageId


  ###*
   * Handler for `SET_SELECTED_MESSAGE` action.
   * It sets state's value as given given messageId.
   *
   * @param {null|string} currentState
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {null|string} nextState
  ###
  setSelectedMessageId: (currentState, { messageId }) -> messageId


