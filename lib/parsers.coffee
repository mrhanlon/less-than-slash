##
# file: parsers.coffee
# author: @marcotheporo
#
# Parser schema
# name: <string> The name of the parser
# trigger: <RegExp|func (string) -> <bool>> A RegExp that when tested
#   using string.match(trigger), or a function that when tested using
#   trigger(string) will return a boolean based on whether the string may trigger
#   an autocompletion. (this should test for the beginning portion of a closing
#   tag only).
# test: <RegExp> determines whether the given string is a candidate
#   for a full parse, (opening or closing)
# parse: <func (string) -> <TagDescriptor|null>> A function that parses a tag from
#   the front of the given text or rejects by returning null
# getPair: <func (TagDescriptor) -> <string>> renders a closing tag to match
#   that given by the TagDescriptor
#
# TagDescriptor Schema
# opening: <bool>
# closing: <bool>
# selfClosing: <bool>
# element: <string> Whilst required, this property doesn't apply to all types
#   of tags, for example there is only one variety of html comment. If you don't
#   have any unique data to put in here, use the tag type
# type: <string> it's best to just put the parser name in here
# length: <number>
#

module.exports =
  xmlparser:
    name: "xml"
    trigger: /<\/$/
    test: /^</
    parse: (text) ->
      result = {
        opening: false
        closing: false
        selfClosing: false
        element: ''
        type: @name
        length: 0
      }
      match = text.match(/^<(\/)?([^\s\/>]+)(\s+([\w-:]+)(=["'`{](.*?)["'`}])?)*\s*(\/)?>/i)
      if match
        result.element     = match[2]
        result.length      = match[0].length
        if @emptyTags.indexOf(result.element.toLowerCase()) > -1
          result.selfClosing = true
        else
          result.opening     = if match[1] or match[7] then false else true
          result.closing     = if match[1] then true else false
          result.selfClosing = if match[7] then true else false
        result
      else
        null
    getPair: (tagDescriptor) ->
      "</#{tagDescriptor.element}>"
    emptyTags: []
  xmlcdataparser:
    name: 'xml-cdata'
    trigger: /\]\]$/
    test: /^(<!\[|]]>)/
    parse: (text) ->
      result = {
        opening: false
        closing: false
        selfClosing: false
        element: 'xml-cdata'
        type: @name
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
    getPair: () ->
      return "]]>"
  # DISABLED
  xmlcommentparser:
    name: 'xml-comment'
    # FIXME tries to close the comment immediately after you open it
    # eg. Input: `<!--` Result: `<!-->`
    # DISABLED FOR NOW
    trigger: /(--)$/
    test: /^(<!--|-->)/
    parse: (text) ->
      result = {
        opening: false
        closing: false
        selfClosing: false
        element: 'xml-comment'
        type: @name
        length: 0
      }
      match = text.match(/(<!--|-->)/)
      if match
        result.length  = match[0].length
        result.opening = if match[1] then true else false
        result.closing = if match[2] then true else false
        result
      else
        null
    getPair: () ->
      return "-->"
  underscoretemplateparser:
    name: 'underscore-template',
    trigger: null
    test: /<%=.+?%>/
    parse: (text) ->
      {
        type: @name,
        selfClosing: true,
        length: text.match(@test)[0].length
      }
    getPair: null
  # DISABLED
  mustacheparser:
    name: 'mustache',
    trigger: /\{\{\/$/
    test: /^{{[\^\/#]/
    parse: (text) ->
      result = {
        opening: false
        closing: false
        selfClosing: false
        element: ''
        type: @name
        length: 0
      }
      match = text.match(/\{\{([#\/])([^\s]+?)(\s+?([^\s]+?))?(\s)*?\}\}/i)
      if match
        console.log match
        result.opening = if match[1] is '#' then true else false
        result.closing = not result.opening
        result.element = match[2]
        result.length = match[0].length
        return result
      else
        return null
    getPair: (tagDescriptor) ->
      # FIXME HACK If you type `{{`, the editor will autmagically insert the
      #   matching `}}`. If we include the `}}` in the rendered tag then after
      #   completing you get `{{/blah}}}}`. Autocomplete plus is smart enough
      #   to mitigate this so I'm not sure which approach to use.
      "{{/#{tagDescriptor.element}}}"