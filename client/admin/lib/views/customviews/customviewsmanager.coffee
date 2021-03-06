kd = require 'kd'
KDButtonView = kd.ButtonView
CustomViewsAdminView = require './customviewsadminview'
HomePageCustomViewItem = require './homepagecustomviewitem'
WidgetCustomViewItem = require './widgetcustomviewitem'
JView = require 'app/jview'
kookies = require 'kookies'


module.exports = class CustomViewsManager extends JView

  cookieName = 'custom-partials-preview-mode'

  constructor: (options = {}, data) ->

    options.cssClass = 'custom-views'

    super options, data

    @previewButton = new KDButtonView
      title        : 'PREVIEW'
      cssClass     : 'solid green preview'
      callback     : @bound 'togglePreview'

    if @isPreviewMode()
      @previewButton.setTitle   'CANCEL PREVIEW'
      @previewButton.unsetClass 'green'

    @homePages  = new CustomViewsAdminView
      title     : 'Home Pages'
      viewType  : 'HOME'
      cssClass  : 'home-pages'
      itemClass : HomePageCustomViewItem

    @widgets    = new CustomViewsAdminView
      title     : 'Widgets'
      viewType  : 'WIDGET'
      cssClass  : 'widgets'
      itemClass : WidgetCustomViewItem


  togglePreview: ->

    isPreview = @isPreviewMode()

    if isPreview
      kookies.set cookieName, no
      @previewButton.setTitle 'PREVIEW'
      @previewButton.setClass 'green'
    else
      kookies.set cookieName, yes
      @previewButton.setTitle   'CANCEL PREVIEW'
      @previewButton.unsetClass 'green'


  isPreviewMode: -> kookies.get(cookieName) is 'true'


  pistachio: ->

    '''
      <div class="button-container">
        {{> @previewButton}}
      </div>
      {{> @homePages}}
      {{> @widgets}}
    '''
