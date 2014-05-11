{WorkspaceView} = require 'atom'
LessThanSlash = require '../lib/less-than-slash'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "LessThanSlash", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('less-than-slash')

  describe "when the less-than-slash:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.less-than-slash')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'less-than-slash:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.less-than-slash')).toExist()
        atom.workspaceView.trigger 'less-than-slash:toggle'
        expect(atom.workspaceView.find('.less-than-slash')).not.toExist()
