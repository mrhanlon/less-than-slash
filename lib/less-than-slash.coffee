##
# file: less-than-slash.coffee
# author: @mrhanlon
#

{
  xmlparser,
  xmlcdataparser,
  xmlcommentparser,
  underscoretemplateparser,
  mustacheparser
} = require './parsers'

module.exports =

  parsers: [
    xmlparser,
    xmlcdataparser,
    xmlcommentparser,
    underscoretemplateparser,
    # mustacheparser
  ]

  config:
    completionMode:
      title: "Completion Mode"
      description: "Choose immediate to have your tags completed immediately (the traditional way). Choose suggest to have them appear in an autocomplete suggestion box."
      type: "string",
      default: "Immediate"
      enum: ["Immediate", "Suggest"]
    emptyTags:
      title: "Empty tags"
      description: "Elements that do not need a matching closing tag."
      type: "string"
      default: [
        "!doctype",
        "br",
        "hr",
        "img",
        "input",
        "link",
        "meta",
        "area",
        "base",
        "col",
        "command",
        "embed",
        "keygen",
        "param",
        "source",
        "track",
        "wbr"
      ].join(" ")

  activate: (state) ->
    # Register config change handler to update the empty tags list
    atom.config.observe "less-than-slash.emptyTags", (value) ->
      xmlparser.emptyTags = (tag.toLowerCase() for tag in value.split(/\s*[\s,|]+\s*/))
    atom.config.observe "less-than-slash.completionMode", (value) =>
      @forceComplete = value.toLowerCase() is "immediate"

    @forceCompleter = atom.workspace.observeTextEditors (editor) =>
      buffer = editor.getBuffer()
      buffer.onDidChange (event) =>
        if event.newText is '' then return
        if not @forceComplete then return
        if prefix = @getPrefix(editor, event.newRange.end, @parsers)
          console.log "prefix is", prefix
          if completion = @getCompletion(editor, event.newRange.end, prefix)
            console.log completion
            buffer.delete [
              [event.newRange.end.row, event.newRange.end.column - prefix.length]
              event.newRange.end
            ]
            buffer.insert [event.newRange.end.row, event.newRange.end.column - prefix.length], completion

    @provider =
      selector: ".text, .source"
      inclusionPriority: 1
      excludeLowerPriority: false
      getSuggestions: ({editor, bufferPosition, scopeDescriptor, activatedManually}) =>
        if @forceComplete then return []
        if prefix = @getPrefix(editor, bufferPosition, @parsers)
          if completion = @getCompletion editor, bufferPosition, prefix
            return [{
              text: completion
              prefix: unless activatedManually then prefix else undefined
              type: 'tag'
            }]

  deactivate: ->
    @forceCompleter.dispose()

  getCompletion: (editor, bufferPosition, prefix) ->
    text = editor.getTextInRange [[0, 0], bufferPosition]
    console.log text
    unclosedTags = @reduceTags(@traverse(text, @parsers))
    console.log unclosedTags
    if tagDescriptor = unclosedTags.pop()
      console.log prefix, tagDescriptor, @getParser(tagDescriptor.type, @parsers).trigger, @matchPrefix(prefix, @getParser(tagDescriptor.type, @parsers))
      # Check that this completion corresponds to the trigger
      if @matchPrefix(prefix, @getParser(tagDescriptor.type, @parsers))
        console.log 'the completion is ', @getParser(tagDescriptor.type, @parsers).getPair(tagDescriptor)
        return @getParser(tagDescriptor.type, @parsers).getPair(tagDescriptor)
    return null

  provide: ->
    @provider

  # Pure logic

  traverse: (text, parsers) ->
    tags = []
    loop
      if text is ''
        break
      newIndex = 1
      for index, parser of parsers
        if text.match(parser.test)
          if tagDescriptor = parser.parse(text)
            tags.push tagDescriptor
            newIndex = tagDescriptor.length
            break
      text = text.substr newIndex
    tags

  reduceTags: (tags) ->
    result = []
    loop
      tag = tags.shift()
      if not tag then break
      switch
        when tag.opening
          result.push tag
        when tag.closing
          _result = result.slice()
          foundMatchingTag = false
          while result.length
            previous = result.pop()
            if previous.element is tag.element and previous.type is tag.type
              foundMatchingTag = true
              break
          unless foundMatchingTag
            result = _result
        when tag.selfClosing
        else
          throw new Error("Invalid parse")
    result

  # Utils
  getPrefix: (editor, bufferPosition, parsers) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    for index, parser of parsers
      if match = @matchPrefix line, parser
        return match
    return false

  matchPrefix: (text, parser) ->
    if typeof parser.trigger is 'function' then parser.trigger(text) else text.match(parser.trigger)?[0]

  getParser: (name, parsers) ->
    for index, parser of parsers
      if parser.name is name
        return parser
    null
