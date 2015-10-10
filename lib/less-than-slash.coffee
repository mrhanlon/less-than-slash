##
# file: less-than-slash.coffee
# author: @mrhanlon
#
module.exports =
  emptyTags: []

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
        if event.newText == "/"
          if event.newRange.start.column > 0
            checkText = buffer.getTextInRange [[event.newRange.start.row, event.newRange.start.column - 2], [event.newRange.end.row, event.newRange.end.column]]
            # Check if we just typed a closing tag </
            # We need to substr relative to the length of the checkText cause
            # it could be only 2 chars long if we type </ at the start of a line
            if checkText.substr(checkText.length - 2, checkText.length) == "</"
              text = buffer.getTextInRange [[0, 0], event.oldRange.end]
              stack = @findTagsIn text
              if stack.length
                tag = stack.pop()
                buffer.insert event.newRange.end, "#{tag.element}>"
            # Check if we just typed a handlebars closing tag {{/
            else if checkText == '{{/'
              text = buffer.getTextInRange [[0, 0], event.oldRange.end]
              stack = @findTagsIn text
              if stack.length
                tag = stack.pop()
                buffer.insert event.newRange.end, "#{tag.element}"

  findTagsIn: (text) ->
    stack = []
    while text
      if text[0...4] is "<!--"
        if (_text = @handleComment text)?
          text = _text
        else
          stack = []
          text = text[4..]
      else if text[0...9] is "<![CDATA["
        if (_text = @handleCDATA text)?
          text = _text
        else
          stack = []
          text = text[9..]
      else if text[0] is "<" or text[0...2] is '{{'
        text = @handleTag text, stack
      else
        index = @minIndex(text.indexOf("<"), text.indexOf("{{"))
        if !!~index
          text = text.substr index
        else
          break
    stack

  # Finds the minimum index out of two indexes, taking into account indexes of -1
  minIndex: (a, b) ->
    return a if a is b
    return a if b < 0
    return b if a < 0
    return a if a < b
    return b if b < a

  handleComment: (text) ->
    ind = text.indexOf '-->'
    if !!~ind
      text.substr ind + 3
    else
      null

  handleCDATA: (text) ->
    ind = text.indexOf ']]>'
    if !!~ind
      text.substr ind + 3
    else
      null

  handleTag: (text, stack) ->
    if tag = @parse(text)
      if tag.opening
        # opening tag, possibly empty
        stack.push {element: tag.element, brackets: tag.brackets} unless @isEmpty(tag.element)
      # tag
      else if tag.closing
        # closing tag: find matching opening tag (if one exists)
        while stack.length
          currentTag = stack.pop()
          break if currentTag.element is tag.element and currentTag.brackets is tag.brackets
      else if tag.selfClosing
        # self closing tag: ignore it
      else
        console.error 'There are problems...'
      text.substr tag.length
    else
      # no match
      text.substr 1

  parse: (text) ->
    if text[0] == '<'
      return @parseTag(text)
    if text[0...2] == '{{'
      return @parseHandlebars(text)
    return null

  parseHandlebars: (text) ->
    result = {
      opening: false
      closing: false
      element: ''
      brackets: '{{'
    }
    match = text.match(/\{\{([#\/])([^\s\/>]+)(\s+([\w-:]+?))*?\s*?\}\}/i)
    if match
      result.element     = match[2]
      result.length      = match[0].length
      result.opening     = if match[1] is '#' then true else false
      result.closing     = if match[1] is '/' then true else false
      result.selfClosing = false
      result
    else
      null

  parseTag: (text) ->
    result = {
      opening: false
      closing: false
      selfClosing: false
      element: ''
      brackets: '<'
      length: 0
    }
    match = text.match(/<(\/)?([^\s\/>]+)(\s+([\w-:]+)(=["'{](.*?)["'}])?)*\s*(\/)?>/i)
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
