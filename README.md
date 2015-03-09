# </ Less Than-Slash

[![Build Status](https://travis-ci.org/mrhanlon/less-than-slash.png)](https://travis-ci.org/mrhanlon/less-than-slash)

Atom.io package for closing open tags when less-than, slash (`</`) is typed, like in Sublime Text 3.


![Less Than Slash](https://mrhanlon.github.io/images/less-than-slash.gif)

## Installation

`apm install less-than-slash`

## Settings

You can specify a list of "Empty Tags" to be ignored from auto-closing. The default value for "Empty Tags" is:

`br`, `hr`, `img`, `input`, `link`, `meta`, `area`, `base`, `col`, `command`, `embed`, `keygen`, `param`, `source`, `track`, `wbr`

The plugin will automatically ignore any self-closing tags. This is useful for frameworks like Angular.js, which allows the definition of custom elements.

## Releases

### v0.4.0

Now automatically ignores self-closed tags, e.g. `<my-element />`, without needing to specify in `@emptyTags`.

### v0.3.4

Now with more CoffeeScript!

### v0.3.3

Documentation update

### v0.3.2

Documentation update

### v0.3.1

Fix multi-line editing not always performing as expected

### v0.3.0

Remove deprecated API calls

### v0.2.0

Bug fixes

### v0.1.1

Bug fixes

### v0.1.0

Initial release
