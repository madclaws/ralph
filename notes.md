## Things we are not doing (as of now)

- Having a lockfile system for updating .git/HEAD - Can try with Genserver first before trying with a traditional lock system.

- Maybe use a gb_tree/OrderedMap library for keeping the order in Tree object entries

- Not using lockfile for index updation

- ctime_nsec is 0 atp, and that's the only differnece in .git's index and ralph's index.
