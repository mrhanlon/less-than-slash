##
# file: less-than-slash.coffee
# author: @mrhanlon
#
module.exports =
  emptyTags: []

  disposable: {}

  config:
    emptyTags:
      type: "string"
      default: "!doctype, br, hr, img, input, link, meta, area, base, col, command, embed, keygen, param, source, track, wbr"

  deactivate: (state) ->
    @disposable[key].dispose() for key in Object.keys @disposable

  activate: (state) ->
    # Register config change handler to update the empty tags list
    atom.config.observe "less-than-slash.emptyTags", (value) =>
      @emptyTags = (tag.toLowerCase() for tag in value.split(/\s*[\s,|]+\s*/))

    @disposable._root = atom.workspace.observeTextEditors (editor) =>
      buffer = editor.getBuffer()
      if not @disposable[buffer.id]
        @disposable[buffer.id] = buffer.onDidChange (event) =>
          if event.newText == "/"
            # Ignore it if its right at the start of a line
            if event.newRange.start.column > 0
              getCheckText = ->
                buffer.getTextInRange([
                  [event.newRange.start.row, 0],
                  event.newRange.end
                ])
              getText = ->
                buffer.getTextInRange [[0, 0], event.oldRange.end]
              if textToInsert = @onSlash getCheckText, getText
                buffer.delete [
                  [event.newRange.end.row, event.newRange.end.column - 2],
                  event.newRange.end
                ]
                buffer.insert [
                    event.newRange.end.row, event.newRange.end.column - 2
                  ], textToInsert

        buffer.onDidDestroy (event) =>
          if @disposable[buffer.id]
            @disposable[buffer.id].dispose()
            delete @disposable[buffer.id]

  # Takes functions that provide the data so we can lazily collect them
  onSlash: (getCheckText, getText) ->
    checkText = getCheckText()
    if @stringEndsWith checkText, '</'
      text = getText()
      if tag = @getNextCloseableTag text
        if tag.type == "xml"
          return "</#{tag.element}>"
        else
          return "#{tag.element}"
    return null

  getNextCloseableTag: (text) ->
    unclosedTags = @findUnclosedTags text
    if nextCloseableTag = unclosedTags.pop()
      return nextCloseableTag
    return null

  # When a tag is opened a record of it is added to the stack, when the
  # corresponding closing tag is found, its record is removed from the stack.
  findUnclosedTags: (text) ->
    unclosedTags = []
    while text != ''
      if @preTests.indexOf(text[0]) > -1
        text = @handleNextTag text, unclosedTags
      else
        index = @preTests
          .map((testChar) -> text.indexOf(testChar))
          .reduce(@minIndex)
        if !!~index
          text = text.substr index
    return unclosedTags

  handleNextTag: (text, unclosedTags) ->
    if tag = @parseNextTag text
      if tag.opening
        # opening tag, possibly empty
        unclosedTags.push {element: tag.element, type: tag.type} unless @isEmpty(tag.element)
      else if tag.closing
        # closing tag: find matching opening tag (if one exists)
        _unclosedTags = unclosedTags.slice()
        foundMatchingTag = false
        while unclosedTags.length
          currentTag = unclosedTags.pop()
          if currentTag.element is tag.element and currentTag.type is tag.type
            foundMatchingTag = true
            break
        # If we didn't find a matching tag, we've just eaten through our stack!
        # We have to revert it
        if !foundMatchingTag
          unclosedTags.splice 0, 0, _unclosedTags...
      else if tag.selfClosing
        # self closing tag: ignore it
      else
        console.error "This should be impossible..."
      return text.substr tag.length
    else
      # no match
      return text.substr 1

  parseNextTag: (text) ->
    for parser in @parsers
      for test in parser.test
        if @stringStartsWith(text, test)
          return this[parser.parse](text)
    null

  # Parsers must specify string match based tests for preliminary matching,
  # after which they will be passed on to the parsing function which may either
  # return a tag object or reject by passing null
  parsers: [
    {
      test: ["<!--", "-->"]
      parse: 'parseXMLComment'
    }
    {
      test: ["<![CDATA[", "]]>"]
      parse: 'parseXMLCDATA'
    }
    {
      test: ["<%=", "%>"]
      parse: 'parseNoOp'
    }
    {
      test: ["<"]
      parse: 'parseXMLTag'
    }
  ]

  # Preliminary tests are used by findUnclosedTags for skipping over large
  # potions of text. This should include each unique character lying at the
  # beginning of a parser test. Failing to include the preTest for a parser
  # will cause less-than-slash to ignore certain tags and produce unexpected
  # outputs
  # This could be computed by using
  # @parsers
  #   .map((parser) -> parser.test)
  #   .reduce((a, b) -> a.concat(b))
  #   .reduce((test) -> test[0])
  #   .reduce((preTests, a) ->
  #     if preTests.indexOf(a) === -1 then preTests.concat([a]) else preTests
  #    , [])
  # Perhaps we could compute this at init time, but I'm, just hard coding it for now
  preTests: ["<", "]", "-"]

  parseNoOp: (text) ->
    null

  parseXMLTag: (text) ->
    result = {
      opening: false
      closing: false
      selfClosing: false
      element: ''
      type: 'xml'
      length: 0
    }
    match = text.match(/<(\/)?([^\s\/>]+)(\s+([\w-:]+)(=["'`{](.*?)["'`}])?)*\s*(\/)?>/i)
    if match
      result.element     = match[2]
      result.length      = match[0].length
      result.opening     = if match[1] or match[7] then false else true
      result.closing     = if match[1] then true else false
      result.selfClosing = if match[7] then true else false
      result
    else
      null

  parseXMLComment: (text) ->
    result = {
      opening: false
      closing: false
      selfClosing: false
      element: '-->'
      type: 'xml-comment'
      length: 0
    }
    match = text.match(/(<!--)|(-->)/)
    if match
      result.length  = match[0].length
      result.opening = if match[1] then true else false
      result.closing = if match[2] then true else false
      result
    else
      null

  parseXMLCDATA: (text) ->
    result = {
      opening: false
      closing: false
      selfClosing: false
      element: ']]>'
      type: 'xml-cdata'
      length: 0
    }
    match = text.match(/(<!\[CDATA\[)|(\]\]>)/i)
    if match
      result.length  = match[0].length
      result.opening = if match[1] then true else false
      result.closing = if match[2] then true else false
      result
    else
      null

  isEmpty: (tag) ->
    if tag
      @emptyTags.indexOf(tag.toLowerCase()) > -1
    else
      false

  # Utils

  # Finds the minimum index out of two indexes, taking into account indexes of -1
  minIndex: (a, b) ->
    return a if a is b
    return a if b < 0
    return b if a < 0
    return a if a < b
    return b if b < a

  # Checks if one string ends in another
  stringEndsWith: (a, b) ->
    a.substr(a.length - b.length, a.length) == b

  stringStartsWith: (a, b) ->
    a.substr(0, b.length) == b
