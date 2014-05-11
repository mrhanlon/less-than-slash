module.exports =
  emptyTags: []

  insertingTags: false

  configDefaults:
    emptyTags: "br, hr, img, input, link, meta, area, base, col, command, embed, keygen, param, source, track, wbr"

  activate: (state) ->
    atom.config.observe "less-than-slash.emptyTags", (value) =>
      @emptyTags = tag.toLowerCase() for tag in value.split(/\s*[\s,|]+\s*/)

    self = @

    atom.workspaceView.eachEditorView (editorView) ->
      editor = editorView.getEditor()
      buffer = editor.getBuffer()
      buffer.on "changed", (event) =>
        if !self.insertingTags and event.newText == "/"
          range = event.newRange
          if range.start.column > 0
            range = [[range.start.row, range.start.column - 1], [range.end.row, range.end.column]]
            checkText = buffer.getTextInRange range
            if checkText == "</"
              text = buffer.getTextInRange [[0, 0], event.oldRange.end]
              stack = self.findTagsIn text
              if stack.length
                tag = stack.pop()
                setTimeout ->
                  buffer.insert event.newRange.end, "#{tag}>"
                  editor.autoIndentSelectedRows()

  closeCurrentTag: (editor, selection) ->
    @insertingTags = true
    buffer = editor.getBuffer()
    position = selection.cursor.getBufferPosition().toArray()
    text = buffer.getTextInRange [[0, 0], position]
    stack = @findTagsIn text
    if stack.length
      @insertClosingTag selection, stack.pop()
      @insertingTags = false

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

  isEmpty: (tag) ->
    @emptyTags.indexOf(tag.toLowerCase()) > -1
