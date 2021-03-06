kd                   = require 'kd'
KDButtonView         = kd.ButtonView
KDCustomHTMLView     = kd.CustomHTMLView
KDFormViewWithFields = kd.FormViewWithFields
KDInputView          = kd.InputView
KDNotificationView   = kd.NotificationView
remote               = require('app/remote').getInstance()
s3upload             = require 'app/util/s3upload'
whoami               = require 'app/util/whoami'
isKoding             = require 'app/util/isKoding'
showError            = require 'app/util/showError'
JView                = require 'app/jview'
AvatarStaticView     = require 'app/commonviews/avatarviews/avatarstaticview'
Encoder              = require 'htmlencode'
VerifyPINModal       = require 'app/commonviews/verifypinmodal'
VerifyPasswordModal  = require 'app/commonviews/verifypasswordmodal'
async                = require 'async'
KodingSwitch         = require 'app/commonviews/kodingswitch'


module.exports = class AccountEditUsername extends JView

  notify = (msg, duration = 2000) ->
    new KDNotificationView
      title    : msg
      duration : duration


  constructor: (options = {}, data) ->

    super options, data

    @initViews()


  initViews: ->

    @account = whoami()

    @avatar = new AvatarStaticView @getAvatarOptions(), @account

    @uploadAvatarBtn  = new KDButtonView
      style           : 'solid small green'
      cssClass        : 'upload-avatar'
      title           : 'Upload Image'
      loader          : yes

    @uploadAvatarInput = new KDInputView
      type            : 'file'
      cssClass        : 'AppModal--account-avatarArea-buttons-upload'
      change          : @bound 'uploadInputChange'
      attributes      :
        accept        : 'image/*'

    @useGravatarBtn  = new KDButtonView
      style          : 'solid small gray'
      cssClass       : 'use-gravatar'
      title          : 'Use Gravatar'
      loader         : yes
      callback       : =>
        @account.modify { 'profile.avatar' : '' }, (err) =>
          console.warn err  if err
          @useGravatarBtn.hideLoader()

    @userProfileFormFields =
      firstName          :
        cssClass         : 'Formline--half'
        placeholder      : 'firstname'
        name             : 'firstName'
        label            : 'Name'
      lastName           :
        cssClass         : 'Formline--half'
        placeholder      : 'lastname'
        name             : 'lastName'
        label            : 'Last name'
      email              :
        cssClass         : 'Formline--half'
        placeholder      : 'you@yourdomain.com'
        name             : 'email'
        testPath         : 'account-email-input'
        label            : 'Email'
      username           :
        cssClass         : 'Formline--half'
        placeholder      : 'username'
        name             : 'username'
        label            : 'Username'
        attributes       :
          readonly       : "#{not /^guest-/.test @account.profile.nickname}"
        testPath         : 'account-username-input'
      verifyEmail        :
        itemClass        : KDCustomHTMLView
        tagName          : 'a'
        partial          : "You didn't verify your email yet <span>Verify now</span>"
        cssClass         : 'hidden action-link verify-email'
        testPath         : 'account-email-edit'
        click            : @bound 'verifyUserEmail'
      passwordHeader     :
        itemClass        : KDCustomHTMLView
        partial          : 'CHANGE PASSWORD'
        cssClass         : 'AppModal-sectionHeader'
      password           :
        cssClass         : 'Formline--half'
        placeholder      : 'password'
        name             : 'password'
        type             : 'password'
        label            : 'Password'
      confirm            :
        cssClass         : 'Formline--half'
        placeholder      : 'confirm password'
        name             : 'confirmPassword'
        type             : 'password'
        label            : 'Password (again)'

    if isKoding()

      @userProfileFormFields.locationHeader =
        itemClass        : KDCustomHTMLView
        partial          : 'LOCATION SERVICES'
        cssClass         : 'AppModal-sectionHeader'

      @userProfileFormFields.shareLocationLabel =
        itemClass        : KDCustomHTMLView
        partial          : 'Share my location when I post on a #channel'
        tagName          : 'ul'
        cssClass         : 'AppModal--account-switchList left-aligned'
        name             : 'shareLocationLabel'
        nextElement      :
          shareLocation      :
            defaultValue     : whoami().shareLocation
            itemClass        : KodingSwitch
            #cssClass         : 'AppModal--account-switchList'
            name             : 'shareLocation'

    @userProfileForm = new KDFormViewWithFields
      cssClass             : 'AppModal-form'
      fields               : @userProfileFormFields
      buttons              :
        Save               :
          title            : 'Save Changes'
          type             : 'submit'
          style            : 'solid green small'
          loader           : yes
      callback             : @bound 'update'


  uploadInputChange: ->

    @uploadAvatarBtn.showLoader()

    file = @uploadAvatarInput.getElement().files[0]

    return @uploadAvatarBtn.hideLoader()  unless file

    mimeType      = file.type
    reader        = new FileReader
    reader.onload = (event) =>
      dataURL     = event.target.result
      [_, base64] = dataURL.split ','

      @uploadAvatar
        mimeType : mimeType
        content  : file
      , =>
        @uploadAvatarBtn.hideLoader()

    reader.readAsDataURL file


  uploadAvatar: (avatar, callback) ->

    { mimeType, content } = avatar

    s3upload
      name    : "avatar-#{Date.now()}"
      content : content
      mimeType: mimeType
      timeout : 30000
    , (err, url) =>

      @uploadAvatarBtn.hideLoader()

      return showError err  if err

      @account.modify { 'profile.avatar': "#{url}" }


  update: (formData) ->

    { JUser } = remote.api
    { email, password, confirmPassword, firstName, lastName, username, shareLocation } = formData
    skipPasswordConfirmation = no
    queue = [
      (next) ->
        # update firstname and lastname
        me = whoami()

        me.modify {
          'profile.firstName': firstName,
          'profile.lastName' : lastName
          'shareLocation'    : formData.shareLocation
        }, (err) ->
          return next err.message  if err
          me.shareLocation = formData.shareLocation
          next()

      (next) =>
        return next() if email is @userInfo.email

        options = { skipPasswordConfirmation, email }
        @confirmCurrentPassword options, (err) =>
          return next err  if err

          JUser.changeEmail { email }, (err, result) =>
            return next err.message  if err

            skipPasswordConfirmation = true
            modal = new VerifyPINModal 'Update E-Mail', (pin) =>
              remote.api.JUser.changeEmail { email, pin }, (err) =>
                return next err.message  if err
                @userInfo.email = email
                next()
            modal.once 'ModalCancelled', -> next 'cancelled'

      (next) =>
        # on third turn update password
        # check for password confirmation
        if password isnt confirmPassword
          return next 'Passwords did not match'

        #check passworg lenght
        if password isnt '' and password.length < 8
          return next 'Passwords should be at least 8 characters'

        # if password is empty than discard operation
        if password is ''
          { token } = kd.utils.parseQuery()
          return next 'You should set your password'  if token
          return next()

        JUser.fetchUser (err, user) =>
          return next 'An error occurred'  if err

          skipPasswordConfirmation = true  if user.passwordStatus isnt 'valid'
          @confirmCurrentPassword { skipPasswordConfirmation }, (err) =>
            return next err  if err
            JUser.changePassword password, (err, docs) =>
              @userProfileForm.inputs.password.setValue ''
              @userProfileForm.inputs.confirm.setValue ''
              if err
                return next()  if err.message is 'PasswordIsSame'
                return next err.message
              return next()

      (next) ->
        notify 'Your account information is updated.'
        next()
    ]

    async.series queue, (err) =>
      notify err  if err and err isnt 'cancelled'
      @hideSaveButtonLoader()


  verifyUserEmail: ->

    { email } = @userInfo
    { nickname, firstName, lastName } = @account.profile

    notify = (message) ->
      new KDNotificationView
        title    : message
        duration : 3500

    remote.api.JUser.verifyByPin { resendIfExists: yes }, (err) =>

      @userProfileForm.fields.verifyEmail.hide()
      @userProfileForm.inputs.verifyEmail.hide()
      return showError err if err

      notify "We've sent you a confirmation mail.", 3500

  confirmCurrentPassword: (opts, callback) ->

    { skipPasswordConfirmation, email } = opts

    return callback null  if skipPasswordConfirmation

    modal = new VerifyPasswordModal 'Confirm', '', (currentPassword) ->
      options = { password: currentPassword, email }
      remote.api.JUser.verifyPassword options, (err, confirmed) ->

        return callback err.message  if err
        return callback 'Current password cannot be confirmed'  unless confirmed

        callback null

    @hideSaveButtonLoader()


  viewAppended: ->

    { JPasswordRecovery, JUser } = remote.api
    { token } = kd.utils.parseQuery()
    if token
      JPasswordRecovery.validate token, (err, isValid) ->
        if err and err.short isnt 'redeemed_token'
          notify err.message
        else if isValid
          notify 'Thanks for confirming your email address'

    kd.singletons.mainController.ready =>
      whoami().fetchEmailAndStatus (err, userInfo) =>

        return kd.warn err  if err

        @userInfo = userInfo

        super

        @putDefaults()


  putDefaults: ->

    { email } = @userInfo
    { nickname, firstName, lastName } = @account.profile

    @userProfileForm.inputs.email.setDefaultValue Encoder.htmlDecode email
    @userProfileForm.inputs.username.setDefaultValue Encoder.htmlDecode nickname
    @userProfileForm.inputs.firstName.setDefaultValue Encoder.htmlDecode firstName
    @userProfileForm.inputs.lastName.setDefaultValue Encoder.htmlDecode lastName

    if isKoding()
      @userProfileForm.inputs.shareLocation.setDefaultValue whoami().shareLocation

    { focus } = kd.utils.parseQuery()
    @userProfileForm.inputs[focus]?.setFocus()  if focus

    notify = (message) ->
      new KDNotificationView
        title    : message
        duration : 3500

    if @userInfo.status is 'unconfirmed'
      @userProfileForm.fields.verifyEmail.show()
      @userProfileForm.inputs.verifyEmail.show()

    @userProfileForm.inputs.firstName.setFocus()


  getAvatarOptions: ->
    tagName       : 'figure'
    cssClass      : 'AppModal--account-avatar'
    size          :
      width       : 95
      height      : 95


  hideSaveButtonLoader: -> @userProfileForm.buttons.Save.hideLoader()


  pistachio: ->
    """
    <div class='AppModal--account-avatarArea clearfix'>
      {{> @avatar}}
      <div class="AppModal--account-avatarArea-buttons">
        {{> @uploadAvatarBtn}}
        {{> @uploadAvatarInput}}
        {{> @useGravatarBtn}}
      </div>
    </div>
    {{> @userProfileForm}}
    """
