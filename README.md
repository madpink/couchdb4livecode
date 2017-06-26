# couchdb4livecode 

Daybed - A Library for Apache CouchDB  version:  1.5.0  June 25, 2017

Instructions for use are available in the wiki:
https://github.com/madpink/couchdb4livecode/wiki

*  Note:  FastJSON has been appended to the library, and is used by default for JSON encoding and decoding.
*  The primary commands have "fast." prefixed to the commands to differentiate them from the built in commands (mergJSON).
*  The original is available here: https://github.com/bhall2001/fastjson

I recommend using FastJSON over mergJSON because:

*  MergJSON doesn't reliably create JSON arrays. This seems to be related to the numbering of the Livecode array to be encoded. I'm experimenting with some commands to improve this.
*  I've had difficulties with MergJSON in Ubuntu standalones.
*  FastJSON is easier to use with Livecode-server. (No need to compile a stack and include the external)
