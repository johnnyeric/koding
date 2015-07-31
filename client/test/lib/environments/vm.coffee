helpers = require '../helpers/helpers.js'
assert  = require 'assert'
environmentHelpers = require '../helpers/environmenthelpers.js'

modalSelector = '.machine-settings-modal.AppModal'

module.exports =


  turnOffVm: (browser) ->

    linkSelector  = modalSelector + ' .AppModal-form'
    vmStateModal  = '.env-machine-state .kdmodal-content'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openGeneralSettings(browser)

    browser
      .waitForElementVisible   linkSelector, 20000
      .waitForElementVisible   linkSelector + ' .statustoggle', 20000
      .click                   linkSelector + ' .statustoggle .koding-on-off.on'
      .waitForElementVisible   vmStateModal + ' .state-label.stopping', 20000
      .waitForElementVisible   vmStateModal + ' .state-label.stopped', 300000
      .waitForElementVisible   vmStateModal + ' .turn-on.state-button', 20000 # Assertion
      .end()


  turnOnVm: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)
    browser.end()


  checkVMDiskUsage: (browser) ->

    diskUsageSelector  = modalSelector + ' .disk-usage'
    circularBar        = '.disk-usage-info .circular-progress-bar'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    environmentHelpers.openDiskUsageSettings(browser)

    browser
      .waitForElementVisible   diskUsageSelector, 20000
      .click                   diskUsageSelector
      .waitForElementVisible   circularBar, 20000
      .assert.containsText     circularBar + ' span.percentage', '53%' # Assertion
      .end()

  updateVMNickname: (browser) ->

      vmModal = modalSelector + ' .AppModal-form'
      paragraph = helpers.getFakeText()
      nickname = paragraph.split(' ')[0]

      helpers.beginTest(browser)
      helpers.waitForVMRunning(browser)

      environmentHelpers.openGeneralSettings(browser)

      browser
        .waitForElementVisible  vmModal, 20000
        .waitForElementVisible  vmModal + ' .nickname', 20000
        .click                                   vmModal + ' .nickname .edit'
        .waitForElementVisible  vmModal + ' .nickname input.hitenterview', 20000
        .setValue                           vmModal + ' .nickname input.hitenterview', nickname + '\n'
        .waitForElementVisible  vmModal + ' .nickname .input-wrapper .kdview', 20000
        .assert.containsText        vmModal + ' .nickname .input-wrapper .kdview', nickname # Assertion
        .end()
