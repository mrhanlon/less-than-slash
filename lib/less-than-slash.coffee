##
# file: less-than-slash.coffee
# author: @mrhanlon
#
module.exports =
  emptyTags: []

  insertingTags: false

  config:
    emptyTags:
      type: "string"
      default: "br, hr, img, input, link, meta, area, base, col, command, embed, keygen, param, source, track, wbr"

  activate: (state) ->
    atom.config.observe "less-than-slash.emptyTags", (value) =>
      @emptyTags = (tag.toLowerCase() for tag in value.split(/\s*[\s,|]+\s*/))

    atom.workspace.observeTextEditors (editor) =>
      buffer = editor.getBuffer()
      buffer.onDidChange (event) =>
        if !@insertingTags and event.newText == "/"
          if event.newRange.start.column > 0
            checkText = buffer.getTextInRange [[event.newRange.start.row, event.newRange.start.column - 1], [event.newRange.end.row, event.newRange.end.column]]
            if checkText == "</"
              text = buffer.getTextInRange [[0, 0], event.oldRange.end]
              stack = @findTagsIn text
              if stack.length
                tag = stack.pop()
                buffer.insert event.newRange.end, "#{tag}>"

  findTagsIn: (text) ->
    stack = []
    while text
      if text.substr(0, 4) is "<!--"
        text = @handleComment text
      else if text.substr(0, 1) is "<"
        text = @handleTag text, stack
      else
        index = text.indexOf("<")
        if index > -1
          text = text.substr(index)
        else
          break
    stack

  handleComment: (text) ->
    i = 4
    while i < text.length and text.substr(i, 3) isnt "-->"
      i++
    text.substr i + 3

  handleTag: (text, stack) ->
    if tag = @parseTag(text)
      if tag.opening
        # opening tag, possibly empty
        stack.push tag.element unless @isEmpty(tag.element)
      # tag
      else if tag.closing
        # closing tag: find matching opening tag (if one exists)
        while stack.length
          break if stack.pop() is tag.element
      else if tag.selfClosing
        # self closing tag: ignore it
      else
        console.error 'There are problems...'
      text.substr tag.length
    else
      # no match
      text.substr 1

  parseTag: (text) ->
    result = {
      opening: false
      closing: false
      selfClosing: false
      element: ''
      length: 0
    }
    match = text.match(/<(\/)?([^\s\/>]+)(\s+([\w-]+)(=["'](.*?)["'])?)*\s*(\/)?>/i)
    if match
      result.element     = match[2]
      result.length      = match[0].length
      result.opening     = if match[1] or match[7] then false else true
      result.closing     = if match[1] then true else false
      result.selfClosing = if match[7] then true else false
      result
    else
      null

  isEmpty: (tag) ->
    @emptyTags.indexOf(tag.toLowerCase()) > -1
