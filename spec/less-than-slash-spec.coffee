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


  describe "handleComment does it's thing", ->
    it "skips a comment", ->
      text = "<!-- This is some ipsum --><p>Lorem ipsum...</p>"
      expect(LessThanSlash.handleComment text).toBe "<p>Lorem ipsum...</p>"

    it "returns nothing if comment at end", ->
      text = "<!-- This is a comment at the end -->"
      expect(LessThanSlash.handleComment text).toBe ""

    it "doesn't have a cow if someone tries to start a second comment", ->
      text = "<!-- foobar <!-- For some reason someone did this --> -->"
      expect(LessThanSlash.handleComment text).toBe " -->"

  describe "handleTag does it's thing", ->
    it "finds a open tag", ->
      stack = []
      text = "<div>"
      text = LessThanSlash.handleTag text, stack
      expect(text).toBe ">"
      expect(stack[0]).toBe "div"

    it "finds a close tag and pops the stack", ->
      stack = ["div"]
      text = "</div>"
      text = LessThanSlash.handleTag text, stack
      expect(text).toBe ">"
      expect(stack.length).toBe 0

    it "finds a tag that is in emptyTags and skips it", ->
      stack = []
      text = "<input>"
      text = LessThanSlash.handleTag text, stack
      expect(text).toBe ">"
      expect(stack.length).toBe 0

    it "finds a self closing tag and skips it", ->
      stack = []
      text = "<br/>"
      text = LessThanSlash.handleTag text, stack
      expect(text).toBe ">"
      expect(stack.length).toBe 0

    it "doesn't find a tag and returns text, one char advanced", ->
      stack = []
      text = "<- this guy"
      text = LessThanSlash.handleTag text, stack
      expect(text).toBe "- this guy"
      expect(stack.length).toBe 0

  describe "findTagsIn does it's thing", ->
    it "finds unmatched tags in markup", ->
      text = "<div><p><i></i><span>"
      stack = LessThanSlash.findTagsIn text
      expect(stack.length).toBe 3
      expect(stack[0]).toBe "div"
      expect(stack[1]).toBe "p"
      expect(stack[2]).toBe "span"
