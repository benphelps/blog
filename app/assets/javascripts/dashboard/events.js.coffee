class @DashboardEvents
  constructor: (@options) -> @init()

  init: ->
    @mode        = 'edit'
    @typingTimer = false

    @setEventHandlers()

  setEventHandlers: ->
    @options.el.on 'click', 'body.dashboard div.menu li', (e) => @optionChange($(e.currentTarget))
    @options.el.on 'webkitfullscreenchange mozfullscreenchange fullscreenchange', => @detectFullScreenChange($('body.dashboard li.fullscreen'))
    @options.el.on 'keyup propertychange paste', 'body.dashboard textarea', => @calculateCounts()
    @options.el.on 'focus keydown', 'body.dashboard textarea', => @editorActive()
    @options.el.on 'focus keydown', 'body.dashboard input[name="post[title]"]', => @titleActive()
    @options.el.on 'mousemove', => @removeActive()
    @options.el.on 'click', 'body.dashboard div.posts button', => @loadPosts()
    @options.el.on 'keyup keydown keypress', (e) => @macros(e)
    @options.el.on 'click', 'body.dashboard div.posts li', (e) => @changePost($(e.currentTarget))
    @options.el.on 'post_saved', 'body.dashboard div.notices', (e, data) => @postSaved($(e.currentTarget), data)
    @options.el.on 'keyup', 'body.dashboard textarea', => @saveTimer()
    @options.el.on 'keydown', 'body.dashboard textarea', (e) => @tab(e)

  optionChange: (el) ->
    switch el.attr('class')
      when 'contrast'   then @setContrast(el)
      when 'fullscreen' then @setFullScreen(el)
      when 'publish'    then @publish()
      when 'preview'    then @togglePreview()
      when 'edit'       then @togglePreview()
      when 'save'       then @save()
      when 'destroy'    then @destroy()

  preview: (el) ->
    $('body.dashboard div.menu li.preview').removeClass('preview').addClass('edit').find('a').text('Edit')

    textarea = $('body.dashboard textarea')
    parsed   = marked(textarea.val())

    textarea.hide()

    $('body.dashboard div#preview').html(parsed).show()

    @mode = 'preview'

  edit: ->
    $('body.dashboard div.menu li.edit').removeClass('edit').addClass('preview').find('a').text('Preview')

    $('body.dashboard div#preview').html('').hide()
    $('body.dashboard textarea').show()

    @mode = 'edit'

  togglePreview: ->
    if @mode is 'edit'
      @preview()
    else
      @edit()

  setContrast: (el) ->
    if el.hasClass('contrast-light')
      el.removeClass('contrast-light').addClass('contrast-dark')
      $('body.dashboard, html').addClass('contrast-dark')
    else if el.hasClass('contrast-dark')
      el.removeClass('contrast-dark').addClass('contrast-light')
      $('body.dashboard, html').removeClass('contrast-dark')

  setFullScreen: (el) ->
    if el.hasClass('expand')
      @launchFullScreen()
    else if el.hasClass('shrink')
      @cancelFullScreen()

  launchFullScreen: ->
    container = document.documentElement

    if container.requestFullScreen
      container.requestFullScreen()
    else if container.mozRequestFullScreen
      container.mozRequestFullScreen()
    else if container.webkitRequestFullScreen
      container.webkitRequestFullScreen(Element.ALLOW_KEYBOARD_INPUT)

  cancelFullScreen: ->
    if document.cancelFullScreen
      document.cancelFullScreen()
    else if document.mozCancelFullScreen
      document.mozCancelFullScreen()
    else if document.webkitCancelFullScreen
      document.webkitCancelFullScreen()

  detectFullScreenChange: (el) ->
    if el.hasClass('expand')
      el.removeClass('expand').addClass('shrink')
    else if el.hasClass('shrink')
      el.removeClass('shrink').addClass('expand')

  publish: ->
    $('form').append('<input name="post[published]" type="hidden" value="true" />')

    @save()

  save: ->
    DashboardRequests.save_post()

  destroy: ->
    DashboardRequests.destroy_post()

  calculateCounts: ->
    text  = $('body.dashboard textarea').val()
    words = text.trim().replace(/^\s+/gi, ' ').split(' ')
    words = if words.length is 1 and words[0] is '' then 0 else words.length

    $('body.dashboard span.characters').text("#{text.length} Characters")
    $('body.dashboard span.words').text("#{words} Words")

  editorActive: ->
    @removeActive()

    $('body.dashboard').find('div.menu, div.counts, div.posts, div.notices, input[name="post[title]"]').addClass('editor-active')

  titleActive: ->
    @removeActive()

    $('body.dashboard').find('div.menu, div.counts, div.posts, div.notices, textarea').addClass('editor-active')

  removeActive: ->
    $('body.dashboard').find('div.menu, div.counts, div.posts, div.notices, input[name="post[title]"], textarea').removeClass('editor-active')

  loadPosts: ->
    $('body.dashboard div.posts ul').load('/dashboard/post_listing')

  macros: (event) ->
    document.forms[0].submit() if event.metaKey and event.keyCode is 13

    if event.metaKey and event.keyCode is 83
      event.preventDefault()

      @save()
    else if event.metaKey and event.keyCode is 80
      event.preventDefault()

      @togglePreview()


  tab: (event) ->
    if event.keyCode is 9
      event.preventDefault()

      el    = $('body.dashboard textarea')
      start = el[0].selectionStart
      end   = el[0].selectionEnd

      el.val("#{el.val().substring(0, start)}  #{el.val().substring(end)}")

      el[0].selectionStart = el[0].selectionEnd = start + 2

  changeFormAction: (type, path) ->
    main = '/posts'
    el   = $('form')

    el.find('input[name="_method"]').remove()

    switch type
      when 'patch'
        el.attr('action', "#{main}/#{path}")
        el.find('div').append('<input name="_method" type="hidden" value="patch" />')
      when 'create' then el.attr('action', main)

  changePost: (el) ->
    @edit()

    slug     = el.data('slug')
    title    = $('input[name="post[title]"]')
    textarea = $('textarea[name="post[content]"]')

    if slug is undefined
      @changeFormAction('create')

      title.val('')
      textarea.val('')

      @calculateCounts(textarea)
    else
      $.get "/#{slug}.json", (data) =>
        @changeFormAction('patch', data.id)

        title.val(data.title)
        textarea.val(data.content)

        @calculateCounts(textarea)

  postSaved: (el, data) ->
    @changeFormAction('patch', data.id)

  saveTimer: ->
    unless $('input[name="post[title]"]').val() is ''
      $('body.dashboard div.notices').text('Saving...')

      clearTimeout(@typingTimer)

      @typingTimer = setTimeout =>
        @save()
      , 400
