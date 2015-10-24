##
# file: less-than-slash-spec.coffee
# author: @mrhanlon
#
LessThanSlash = require '../lib/less-than-slash'

describe "LessThanSlash", ->
  activationPromise = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('less-than-slash')

  describe "onSlash", ->
    it "returns the appropriate closing tag", ->
      getCheckText = ->
        '<div class="moo"><a href="/cows">More cows!</'
      getText = ->
        '<div class="moo"><a href="/cows">More cows!<'
      expect(LessThanSlash.onSlash(getCheckText, getText)).toBe '</a>'

      getCheckText = ->
        '<div class="moo"><a href="/cows">More cows!</a></'
      getText = ->
        '<div class="moo"><a href="/cows">More cows!</a><'
      expect(LessThanSlash.onSlash(getCheckText, getText)).toBe '</div>'

    it "also works for comments", ->
      getCheckText = ->
        '<!--<div class="moo"><a href="/cows">More cows!</a></div></'
      getText = ->
        '<!--<div class="moo"><a href="/cows">More cows!</a></div><'
      expect(LessThanSlash.onSlash(getCheckText, getText)).toBe '-->'

      getCheckText = ->
        '<div class="moo"><a href="/cows"><!--More cows!--></'
      getText = ->
        '<div class="moo"><a href="/cows"><!--More cows!--><'
      expect(LessThanSlash.onSlash(getCheckText, getText)).toBe '</a>'

    it "also works inside comments", ->
      getCheckText = ->
        '<!--<div class="moo"><a href="/cows">More cows!</a></'
      getText = ->
        '<!--<div class="moo"><a href="/cows">More cows!</a><'
      expect(LessThanSlash.onSlash(getCheckText, getText)).toBe '</div>'

    it "also works for XML CDATA", ->
      getCheckText = ->
        '<![CDATA[<div class="moo"><a href="/cows">More cows!</a></div></'
      getText = ->
        '<![CDATA[<div class="moo"><a href="/cows">More cows!</a></div><'
      expect(LessThanSlash.onSlash(getCheckText, getText)).toBe ']]>'

      getCheckText = ->
        '<div class="moo"><a href="/cows"><![CDATA[More cows!]]></'
      getText = ->
        '<div class="moo"><a href="/cows"><![CDATA[More cows!]]><'
      expect(LessThanSlash.onSlash(getCheckText, getText)).toBe '</a>'

    it "also works inside XML CDATA", ->
      getCheckText = ->
        '<![CDATA[<div class="moo"><a href="/cows">More cows!</a></'
      getText = ->
        '<![CDATA[<div class="moo"><a href="/cows">More cows!</a><'
      expect(LessThanSlash.onSlash(getCheckText, getText)).toBe '</div>'

    it "returns null if there are no tags to close", ->
      getCheckText = ->
        '<div class="moo"><a href="/cows">More cows!</a></div></'
      getText = ->
        '<div class="moo"><a href="/cows">More cows!</a></div><'
      expect(LessThanSlash.onSlash(getCheckText, getText)).toBe null

      getCheckText = ->
        '</'
      getText = ->
        '<'
      expect(LessThanSlash.onSlash(getCheckText, getText)).toBe null

    it "works around mismatched tags", ->
      getCheckText = ->
        '<div class="moo"><a href="/cows">More cows!</i></'
      getText = ->
        '<div class="moo"><a href="/cows">More cows!</i><'
      expect(LessThanSlash.onSlash(getCheckText, getText)).toBe '</a>'

      getCheckText = ->
        '<div class="moo"><a href="/cows"><em>More cows!</i></a></'
      getText = ->
        '<div class="moo"><a href="/cows"><em>More cows!</i></a><'
      expect(LessThanSlash.onSlash(getCheckText, getText)).toBe '</div>'

  describe "getNextCloseableTag", ->
    it "returns the next closeable tag", ->
      text = "<div>"
      expect(LessThanSlash.getNextCloseableTag(text)).toEqual {
        element: "div",
        type: "xml"
      }

      text = "<div><a><br></a><ul><li></li><li></li></ul>"
      expect(LessThanSlash.getNextCloseableTag(text)).toEqual {
        element: "div",
        type: "xml"
      }

    it "returns null when all tags are closed", ->
      text = "<div><a></a></div>"
      expect(LessThanSlash.getNextCloseableTag(text)).toBe null

  describe "findUnclosedTags", ->
    it "returns a list of unclosed tags", ->
      text = "<div><a></a><em>"
      expect(LessThanSlash.findUnclosedTags(text)).toEqual [
        {
          element: "div",
          type: "xml"
        }
        {
          element: "em",
          type: "xml"
        }
      ]

      text = "<div><a></a></div>"
      expect(LessThanSlash.findUnclosedTags(text)).toEqual []

    it "still works around mismatched tags", ->
      text = "<div></i><a>"
      expect(LessThanSlash.findUnclosedTags(text)).toEqual [
        {
          element: "div",
          type: "xml"
        }
        {
          element: "a",
          type: "xml"
        }
      ]

  describe "handleNextTag", ->
    it "consumes the next tag and places it in the stack", ->
      text = "<div><a>"
      unclosedTags = []
      expect(LessThanSlash.handleNextTag(text, unclosedTags)).toBe "<a>"
      expect(unclosedTags).toEqual [
        {
          element: "div",
          type: "xml"
        }
      ]

    it "consumes the next closing tag and removes it from the stack", ->
      text = "</a></div>"
      unclosedTags = [
        {
          element: "div",
          type: "xml"
        }
        {
          element: "a",
          type: "xml"
        }
      ]
      expect(LessThanSlash.handleNextTag(text, unclosedTags)).toBe "</div>"
      expect(unclosedTags).toEqual [
        {
          element: "div",
          type: "xml"
        }
      ]

    it "discards mismatched tags", ->
      text = "</em></a></div>"
      unclosedTags = [
        {
          element: "div",
          type: "xml"
        }
        {
          element: "a",
          type: "xml"
        }
      ]
      expect(LessThanSlash.handleNextTag(text, unclosedTags)).toBe "</a></div>"
      expect(unclosedTags).toEqual [
        {
          element: "div",
          type: "xml"
        }
        {
          element: "a",
          type: "xml"
        }
      ]

  describe "parseNextTag", ->
    it "parses tags, comments, and cdata", ->
      text = "<div>"
      expect(LessThanSlash.parseNextTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div',
        type: 'xml'
        length: 5
      }

      text = "<!--"
      expect(LessThanSlash.parseNextTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: '-->'
        type: 'xml-comment'
        length: 4
      }

      text = "<![CDATA["
      expect(LessThanSlash.parseNextTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: ']]>'
        type: 'xml-cdata'
        length: 9
      }

  describe "parseXMLTag", ->
    it "parses an opening tag", ->
      text = "<div>"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div',
        type: 'xml'
        length: 5
      }

    it "parses a closing tag", ->
      text = "</div>"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: false
        closing: true
        selfClosing: false
        element: 'div'
        type: 'xml'
        length: 6
      }

    it "parses self closing tags", ->
      text = "<br/>"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: false
        closing: false
        selfClosing: true
        element: 'br'
        type: 'xml'
        length: 5
      }

    it "returns null when there is no tag", ->
      text = "No tag here!"
      expect(LessThanSlash.parseXMLTag text).toBe null

    it "works around element properties", ->
      text = "<div class=\"container\">"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div'
        type: 'xml'
        length: 23
      }

    it "doesn't care which quotes you use", ->
      text = "<div class='container'>"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div'
        type: 'xml'
        length: 23
      }

      text = "<div class=`container`>"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div'
        type: 'xml'
        length: 23
      }

    it "plays nicely with JSX curly brace property values", ->
      text = "<input type=\"text\" disabled={this.props.isDisabled}/>"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: false
        closing: false
        selfClosing: true
        element: 'input'
        type: 'xml'
        length: 53
      }

    it "plays nicely with multiline namespaced attributes", ->
      text = "<elem\n ns1:attr1=\"text\"\n  ns2:attr2=\"text\"\n>"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'elem'
        type: 'xml'
        length: 44
      }

    it "works around weird spacing", ->
      text = "<div  class=\"container\" \n  foo=\"bar\">"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div'
        type: 'xml'
        length: 37
      }

    it "works around lone properties", ->
      text = "<input type=\"text\" required/>"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: false
        closing: false
        selfClosing: true
        element: 'input'
        type: 'xml'
        length: 29
      }

    it "doesn't have a cow when properties contain a '>'", ->
      text = "<p ng-show=\"3 > 5\">Uh oh!"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'p'
        type: 'xml'
        length: 19
      }

    it "finds the expected tag when tags are nested", ->
      text = "<a><i>"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'a'
        type: 'xml'
        length: 3
      }

    it "finds the expected tag when tags with attributes are nested", ->
      text = "<a href=\"#\"><i class=\"fa fa-home\">"
      expect(LessThanSlash.parseXMLTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'a'
        type: 'xml'
        length: 12
      }

  describe "parseXMLComment", ->
    it "parses comments as if they were tags", ->
      text = "<!--"
      expect(LessThanSlash.parseXMLComment text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: '-->'
        type: 'xml-comment'
        length: 4
      }

      text = "-->"
      expect(LessThanSlash.parseXMLComment text).toEqual {
        opening: false
        closing: true
        selfClosing: false
        element: '-->'
        type: 'xml-comment'
        length: 3
      }

  describe "parseXMLCDATA", ->
    it "parses CDATA as if they were tags", ->
      text = "<![CDATA["
      expect(LessThanSlash.parseXMLCDATA text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: ']]>'
        type: 'xml-cdata'
        length: 9
      }

      text = "]]>"
      expect(LessThanSlash.parseXMLCDATA text).toEqual {
        opening: false
        closing: true
        selfClosing: false
        element: ']]>'
        type: 'xml-cdata'
        length: 3
      }

  describe "isEmpty", ->
    it "is true when it isEmpty", ->
      expect(LessThanSlash.isEmpty "br").toBe true

    it "is false when not isEmpty", ->
      expect(LessThanSlash.isEmpty "div").toBe false

  describe "minIndex", ->
    it "returns the lower number", ->
      lower = LessThanSlash.minIndex(3, 5)
      expect(lower).toBe 3

      lower = LessThanSlash.minIndex(5, 3)
      expect(lower).toBe 3

    it "discards a negative index", ->
      lower = LessThanSlash.minIndex(3, -1)
      expect(lower).toBe 3

      lower = LessThanSlash.minIndex(-1, 3)
      expect(lower).toBe 3

    it "passes on double negative indicies", ->
      lower = LessThanSlash.minIndex(-1, -1)
      expect(lower).toBe -1

  describe "stringEndsWith", ->
    it "returns true if the first string ends in the second", ->
      a = "don't have a cow, man!"
      b = "man!"
      expect(LessThanSlash.stringEndsWith(a, b)).toBe true

    it "returns false if the first string does not end in the second", ->
      a = "chunky bacon"
      b = "chunky"
      expect(LessThanSlash.stringEndsWith(a, b)).toBe false

  describe "stringStartsWith", ->
    it "returns true if the first string ends starts with the second", ->
      a = "chunky bacon"
      b = "chunky"
      expect(LessThanSlash.stringStartsWith(a, b)).toBe true

    it "returns false if the first string does not start with the second", ->
      a = "don't have a cow, man!"
      b = "man!"
      expect(LessThanSlash.stringStartsWith(a, b)).toBe false
