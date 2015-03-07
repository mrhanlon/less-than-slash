##
# file: less-than-slash.coffee
# author: @mrhanlon
#
module.exports =
  emptyTags: []

  insertingTags: false

  configDefaults:
    emptyTags: "br, hr, img, input, link, meta, area, base, col, command, embed, keygen, param, source, track, wbr"

  activate: (state) ->
    atom.config.observe "less-than-slash.emptyTags", (value) =>
      @emptyTags = (tag.toLowerCase() for tag in value.split(/\s*[\s,|]+\s*/))

    atom.workspace.observeTextEditors (editor) =>
      buffer = editor.getBuffer()
      buffer.on "changed", (event) =>
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
    # check if it's a self closing tag
    unless match = text.match(/(<.*\/>)/)
      if match = text.match(/<(\/)?([a-z][^\s\/>]*)/i)
        if tag = match[2]
          if match[1]
            # closing tag: find matching opening tag (if one exists)
            while stack.length
              break if stack.pop() is tag
          else
            # opening tag, possibly empty
            stack.push tag unless @isEmpty(tag)
        text.substr match[0].length
      else
        text.substr 1
    else text.substr match[0].length

  isEmpty: (tag) ->
    @emptyTags.indexOf(tag.toLowerCase()) > -1
