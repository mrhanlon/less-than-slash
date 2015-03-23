##
# file: less-than-slash-spec.coffee
# author: @mrhanlon
#
{WorkspaceView} = require 'atom'
LessThanSlash = require '../lib/less-than-slash'

describe "LessThanSlash", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
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

  describe "parseTag does its thing", ->
    it "detects an opening tag", ->
      text = "<div>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div'
        length: 5
      }

    it "detects a closing tag", ->
      text = "</div>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: false
        closing: true
        selfClosing: false
        element: 'div'
        length: 6
      }

    it "detects a self closing tag", ->
      text = "<br/>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: false
        closing: false
        selfClosing: true
        element: 'br'
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
        length: 23
      }

    it "doesn't have a cow when you use the wrong quotes", ->
      text = "<div class='container'>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div'
        length: 23
      }

    it "doesn't have a cow when you use retarded spacing", ->
      text = "<div  class=\"container\" \n  foo=\"bar\">"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'div'
        length: 37
      }

    it "doesn't have a cow when you use lone properties", ->
      text = "<input type=\"text\" required/>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: false
        closing: false
        selfClosing: true
        element: 'input'
        length: 29
      }

    it "doesn't have a cow when properties contain a '>'", ->
      text = "<p ng-show=\"3 > 5\">Uh oh!"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'p'
        length: 19
      }

    it "finds the expected tag when tags are nested", ->
      text = "<a><i>"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'a'
        length: 3
      }

    it "finds the expected tag when tags with attributes are nested", ->
      text = "<a href=\"#\"><i class=\"fa fa-home\">"
      expect(LessThanSlash.parseTag text).toEqual {
        opening: true
        closing: false
        selfClosing: false
        element: 'a'
        length: 12
      }

  describe "handleTag does its thing", ->
    it "finds an opening tag", ->
      stack = []
      text = "<div>"
      text = LessThanSlash.handleTag text, stack
      expect(text).toBe ""
      expect(stack[0]).toBe "div"

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
      expect(stack[0]).toBe "div"
      expect(stack[1]).toBe "p"
      expect(stack[2]).toBe "span"

    it "correctly finds nested tags with attributes", ->
      text = "<a href=\"#\"><i class=\"fa fa-home\">"
      stack = LessThanSlash.findTagsIn text
      expect(stack.length).toBe 2
      expect(stack[0]).toBe "a"
      expect(stack[1]).toBe "i"
