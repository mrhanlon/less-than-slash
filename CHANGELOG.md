### v0.6.0

Fixed deprecation warnings:

- Support new configuration schema

### v0.5.0

Fixed deprecation cop warnings:

- `TextBuffer.on` is deprecated; use `TextBuffer.onDidChange` instead
- Package styles should be in `/styles` not `/stylesheets`. However, less-than-slash doesn't have any styles so just nuked the practically empty stylesheet instead. :fire: :fire: :fire:

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
