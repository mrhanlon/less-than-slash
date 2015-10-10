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

  describe "isEmpty and emptyTags", ->
    it "is true when it isEmpty", ->
      expect(LessThanSlash.isEmpty "br").toBe true
    it "is false when not isEmpty", ->
      expect(LessThanSlash.isEmpty "div").toBe false


  describe "handleComment does its thing", ->
    it "skips a comment", ->
      text = "<!-- This is some ipsum --><p>Lorem ipsum...</p>"
      expect(LessThanSlash.handleComment text).toBe "<p>Lorem ipsum...</p>"

    it "returns nothing if comment at end", ->
      text = "<!-- This is a comment at the end -->"
      expect(LessThanSlash.handleComment text).toBe ""

    it "doesn't have a cow if someone tries to start a second comment", ->
      text = "<!-- foobar <!-- For some reason someone did this --> -->"
      expect(LessThanSlash.handleComment text).toBe " -->"

    it "doesn't complete from outside comment", ->
      text = "<div><!--"
      expect(LessThanSlash.findTagsIn text).toEqual []

    it "correctly completes around comment", ->
        text = "<div><!--<span>-->"
        stack = LessThanSlash.findTagsIn text
        expect(stack[0].element).toBe "div"

    it "completes within comment", ->
        text = "<div><!--<span>"
        stack = LessThanSlash.findTagsIn text
        expect(stack.length).toBe 1
        expect(stack[0].element).toBe "span"

    describe "handleCDATA does its thing", ->
      it "skips a CDATA", ->
        text = "<![CDATA[This is some ipsum]]><p>Lorem ipsum...</p>"
        expect(LessThanSlash.handleCDATA text).toBe "<p>Lorem ipsum...</p>"

      it "returns nothing if CDATA at end", ->
        text = "<![CDATA[This is a CDATA at the end]]>"
        expect(LessThanSlash.handleCDATA text).toBe ""

      it "doesn't complete from outside CDATA", ->
        text = "<div><![CDATA["
        expect(LessThanSlash.findTagsIn text).toEqual []

      it "correctly completes around CDATA", ->
          text = "<div><![CDATA[<span>]]>"
          stack = LessThanSlash.findTagsIn text
          expect(stack[0].element).toBe "div"

      it "completes within CDATA", ->
          text = "<div><![CDATA[<span>"
          stack = LessThanSlash.findTagsIn text
          expect(stack.length).toBe 1
          expect(stack[0].element).toBe "span"

  describe "parseTag does its thing", ->
    it "detects an opening tag", ->
      text = "<div>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div',
        brackets: '<'
        length: 5
      }

    it "detects a closing tag", ->
      text = "</div>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: false
        closing: true
        selfClosing: false
        element: 'div'
        brackets: '<'
        length: 6
      }

    it "detects a self closing tag", ->
      text = "<br/>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: false
        closing: false
        selfClosing: true
        element: 'br'
        brackets: '<'
        length: 5
      }

    it "returns null when there is no tag", ->
      text = "No tag here!"
      expect(LessThanSlash.parseTag text).toBe null

    it "doesn't have a cow when an element has properties", ->
      text = "<div class=\"container\">"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div'
        brackets: '<'
        length: 23
      }

    it "doesn't have a cow when you use the wrong quotes", ->
      text = "<div class='container'>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div'
        brackets: '<'
        length: 23
      }

    it "plays nicely with JSX curly brace property values", ->
      text = "<input type=\"text\"disabled={this.props.isDisabled}/>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: false
        closing: false
        selfClosing: true
        element: 'input'
        brackets: '<'
        length: 52
      }

    it "plays nicely with multiline namespaced attributes", ->
      text = "<elem\n ns1:attr1=\"text\"\n  ns2:attr2=\"text\"\n>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'elem'
        brackets: '<'
        length: 44
      }

    it "doesn't have a cow when you use retarded spacing", ->
      text = "<div  class=\"container\" \n  foo=\"bar\">"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div'
        brackets: '<'
        length: 37
      }

    it "doesn't have a cow when you use lone properties", ->
      text = "<input type=\"text\" required/>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: false
        closing: false
        selfClosing: true
        element: 'input'
        brackets: '<'
        length: 29
      }

    it "doesn't have a cow when properties contain a '>'", ->
      text = "<p ng-show=\"3 > 5\">Uh oh!"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'p'
        brackets: '<'
        length: 19
      }

    it "finds the expected tag when tags are nested", ->
      text = "<a><i>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'a'
        brackets: '<'
        length: 3
      }

    it "finds the expected tag when tags with attributes are nested", ->
      text = "<a href=\"#\"><i class=\"fa fa-home\">"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'a'
        brackets: '<'
        length: 12
      }

  describe "handleTag does its thing", ->
    it "finds an opening tag", ->
      stack = []
      text = "<div>"
      text = LessThanSlash.handleTag text, stack
      expect(text).toBe ""
      expect(stack[0].element).toBe "div"

    it "finds a closing tag and pops the stack", ->
      stack = ["div"]
      text = "</div>"
      text = LessThanSlash.handleTag text, stack
      expect(text).toBe ""
      expect(stack.length).toBe 0

    it "finds a tag that is in emptyTags and skips it", ->
      stack = []
      text = "<input>"
      text = LessThanSlash.handleTag text, stack
      expect(text).toBe ""
      expect(stack.length).toBe 0

    it "finds a self closing tag and skips it", ->
      stack = []
      text = "<br/>"
      text = LessThanSlash.handleTag text, stack
      expect(text).toBe ""
      expect(stack.length).toBe 0

    it "doesn't find a tag and returns text, one char advanced", ->
      stack = []
      text = "<- this guy"
      text = LessThanSlash.handleTag text, stack
      expect(text).toBe "- this guy"
      expect(stack.length).toBe 0

  describe "findTagsIn does its thing", ->
    it "finds unmatched tags in markup", ->
      text = "<div><p><i></i><span>"
      stack = LessThanSlash.findTagsIn text
      expect(stack.length).toBe 3
      expect(stack[0].element).toBe "div"
      expect(stack[1].element).toBe "p"
      expect(stack[2].element).toBe "span"

    it "correctly finds nested tags with attributes", ->
      text = "<a href=\"#\"><i class=\"fa fa-home\">"
      stack = LessThanSlash.findTagsIn text
      expect(stack.length).toBe 2
      expect(stack[0].element).toBe "a"
      expect(stack[1].element).toBe "i"

  describe "parseHandlebars does its thing", ->
    it "detects an opening tag", ->
      text = "{{#if currentUser}}"
      expect(LessThanSlash.parseHandlebars text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'if',
        brackets: '{{'
        length: 19
      }

    it "detects a closing tag", ->
      text = "{{/if}}"
      expect(LessThanSlash.parseHandlebars text).toEqual {
        opening: false
        closing: true
        selfClosing: false
        element: 'if'
        brackets: '{{'
        length: 7
      }

    it "returns null when there is no tag", ->
      text = "No tag here!"
      expect(LessThanSlash.parseHandlebars text).toBe null

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
