New hashmap for c3.

Current one is chained, but I want one that's

- open-addressing (probably don't need anything fancy)
- does not copy keys
- maybe array based? but probably not important for most things
- has a get_or_put (in zig) API, I hit this extremely often.
