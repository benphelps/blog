$ ->
  textareaResize = ->
    textareaSize = document.documentElement.clientHeight - 100

    $('body.dashboard').find('textarea, div#preview').css('height', "#{textareaSize}px")

  $(document).ready ->
    textareaResize()

  $(window).resize ->
    textareaResize()
