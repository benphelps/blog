$ ->
  $('li.contrast').on 'click', ->
    if $(@).hasClass('contrast-light')
      $(@).removeClass('contrast-light').addClass('contrast-dark')
      $('body.dashboard').addClass('contrast-dark')
      $('html').css('background-color', 'black')
    else if $(@).hasClass('contrast-dark')
      $(@).removeClass('contrast-dark').addClass('contrast-light')
      $('body.dashboard').removeClass('contrast-dark')
      $('html').css('background-color', 'white')

    return false

  textareaResize = ->
    textareaSize = document.documentElement.clientHeight - 100

    $('body.dashboard textarea').css('height', "#{textareaSize}px")

  $(document).ready ->
    textareaResize()

  $(window).resize ->
    textareaResize()

  # credit: http://davidwalsh.name/fullscreen
  launchFullScreen = (container) ->
    if container.requestFullScreen
      container.requestFullScreen()
    else if container.mozRequestFullScreen
      container.mozRequestFullScreen()
    else if container.webkitRequestFullScreen
      container.webkitRequestFullScreen(Element.ALLOW_KEYBOARD_INPUT)

  cancelFullScreen = ->
    if document.cancelFullScreen
      document.cancelFullScreen()
    else if document.mozCancelFullScreen
      document.mozCancelFullScreen()
    else if document.webkitCancelFullScreen
      document.webkitCancelFullScreen()

  $('li.fullscreen').on 'click', ->
    if $(@).hasClass('expand')
      launchFullScreen(document.documentElement)
    else if $(@).hasClass('shrink')
      cancelFullScreen()

    return false

  $(document).on 'webkitfullscreenchange mozfullscreenchange fullscreenchange', ->
    el = $('li.fullscreen')

    if el.hasClass('expand')
      el.removeClass('expand').addClass('shrink')
    else if el.hasClass('shrink')
      el.removeClass('shrink').addClass('expand')

  $('body.dashboard li').on 'click', ->
    if $(@).hasClass('publish')
      $('form').append('<input name="post[published]" type="hidden" value="true" />')
      document.forms[0].submit()
    else if $(@).hasClass('save')
      save_post()
    else if $(@).hasClass('destroy')
      $.ajax
        url: $('form').attr('action')
        type: 'DELETE'
        data: { '_method': 'destroy' }
        dataType: 'json'
      .success (data) ->
        $('input[name="post[title]"]').val('')
        $('textarea[name="post[content]"]').val('')

        el = $("li[data-slug='#{data.slug}']")
        el.next().remove()
        el.remove()

        formAction('create')

  $('body.dashboard textarea').on 'keyup propertychange paste', ->
    text  = $(@).val()
    words = text.trim().replace(/^\s+/gi, ' ').split(' ')
    words = if words.length is 1 and words[0] is '' then words = 0 else words.length

    $('span.characters').text("#{text.length} Characters")
    $('span.words').text("#{words} Words")


  activeAreas = $('body.dashboard div.menu, body.dashboard div.counts, body.dashboard div.posts, body.dashboard div.notices')

  $('body.dashboard textarea').on 'focus keydown', ->
    activeAreas.addClass('editor-active')

  $('body.dashboard').on 'mousemove', ->
    activeAreas.removeClass('editor-active')

  formAction = (type, path) ->
    main = '/posts'
    el   = $('form')

    el.find('input[name="_method"]').remove()

    switch type
      when 'patch'
        el.attr('action', "#{main}/#{path}")
        el.find('div').append('<input name="_method" type="hidden" value="patch" />')
      when 'create'
        el.attr('action', main)

  $('body.dashboard div.posts li').on 'click', ->
    slug     = $(@).data('slug')
    title    = $('input[name="post[title]"]')
    textarea = $('textarea[name="post[content]"]')

    if slug is undefined
      formAction('create')
      title.val('')
      textarea.val('')

      $('body.dashboard li.preview').find('a').attr('href', 'javascript:void(0)')
    else
      $.get "/#{slug}.json", (data) ->
        formAction('patch', data.id)
        title.val(data.title)
        textarea.val(data.content)

        $('body.dashboard li.preview').find('a').attr('href', "/#{slug}")

  save_post = ->
    $('form').on 'submit', (event) ->
      event.preventDefault()
      submit = $(@).serialize()

      $.ajax
        url: $(@).attr('action')
        type: 'POST'
        data: submit
        dataType: 'json'
      .success (data) ->
        $('body.dashboard div.notices').trigger('post_saved', [data])
      .error (data) ->
        $('body.dashboard div.notices').text('Not Saved')
        console.log(data)

    $('form').submit()
    $('form').off('submit')

  $('body.dashboard div.notices').on 'post_saved', (event, data) ->
    $(@).text('Saved')

    formAction('patch', data.id)

    $('body.dashboard li.preview').find('a').attr('href', "/#{data.slug}")

  $(document).on 'keyup keydown keypress', (event) ->
    document.forms[0].submit() if event.metaKey and event.keyCode is 13

    if event.metaKey and event.keyCode is 83
      event.preventDefault()

      save_post()

  typingTimer = false

  $('body.dashboard textarea').on 'keyup', ->
    unless $('input[name="post[title]"]').val() is ''
      $('body.dashboard div.notices').text('Saving...')

      clearTimeout(typingTimer)

      typingTimer = setTimeout ->
        save_post()
      , 400

  return
