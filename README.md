# couchdb4livecode
Daybed - A Library for Apache CouchDB

Functions:

####`couch.get(pFunk,pURL,pDB,pDocID,pParams,pOptions,pFormat)`
* The couch.get function retrives a document, multiple documents, or information.

####`couch.put(pFunk,pURL,pDB,pDoc,pParams,pOptions,pFormat)`
* The couch.put function inserts a value or a document into a database.

####`couch.post(pFunk,pURL,pDB,pDoc,pParams,pOptions,pFormat)`
* The couch.post function inserts multiple documents or values into a database.

####`couch.delete(pFunk,pURL,pDB,pDocID,pParams,pOptions,pFormat)`
* The couch.delete function deletes a document or database, or a config key.
	* Note: the database is really deleted, however the document can still be retrieved if the id and rev are known.

##### Parameters

* **pFunk** - (always required) Couch function being called, without the leading underscore, for example "all_docs"
	* a list is included below of functions that have been tested
	* there are four categories of functions:  system, database, document, design document

* **pURL** - (always required) the URL of the CouchDB installation, including "http://", the port numer and a trailing slash
	* For example:   "http://192.168.23.42:5984/"
	* With username/password:    "http://admin:trustno1@192.168.23.42:5984/"

* **pDB** - (required when acting on or retrieving from a database) - the name of the database being accessed
	* should be blank for system functions, must be included for database, document, and design document
		
* **pDocID** - (for get and delete functions) the document "_id" being retrieved
	* should be blank for system and database functions, must be included for document and design document 
	* for design documents, use the pDocID param to specify it
		* for selecting a view from a design document, add a slash with the view name to pDocID, for example: for the following view call /_design/querymon/_view/phone
			* put "querymon/phone" into pDocID
		
* **pDoc** - (for put and post functions) array containing the data being converted into a document for the database
	* should be blank for system functions, must be included in document and design document (also used in a db function)

* **pParams** - an array with any OPTIONAL parameters, with the parameter as a key.
	* These parameters are specified in the CouchDB API
	* For example:  to download documents when running the _all_docs function, and limit the list to only 10 records:
		* `put true into tParams["include_docs"]`
     		* `put 10 into tParams["limit"]`

* **pOptions** - (optional) header options, including authentication, config values and return format

####`couch.securedb(pFunk,pURL,pDB,pOptions,pAdminNames,pAdminRoles,pMemberNames,pMemberRoles)`
The couch.securedb function sets the "_security" document for the specified database.
pFunk - "set" (replace current security), "add" adds user/roles to existing security, "delete" removes user/roles from existing
* pAdminNames - sets the given names up with admin rights (read,write,delete)
* pAdminRoles - sets the given user roles up with admin rights (read,write,delete)
* pMemberNames - sets the given names up with member rights (read only)
* pMemberRoles - sets the given user roles up with member rights (read only)

####`couch.adduserdb(pURL,pUser,pPass,pOptions)`
The couch.adduser function inserts a new record into the "_users" database, creates a database for the user, and 
sets the new user as the admin and member (which makes that user the only one who can access it).
* pUsername - Username of the person signing up.
* pPassword - Password for the account
* pOptions["roles"] - can be used to assign the user to roles, must be in a numbered array
* Note:  only an admin can create a user

####`couch.peruserDB(pUsername)`
Requires "couchperuser" to be installed (https://github.com/etrepum/couchperuser)
The couch.peruserDB function returns the database name associated with the username specified.

**Authentication:** if the CouchDB URL requires authentication, it can be achieved in one of two ways:

Option 1: include the username and password as part of the URL, for example:
	* "http://admin:passw0rd@192.168.0.42:5984/"

Option 2: use the pOptions parameter, and the script will encode the username and password into the httpheaders:
	* put "admin" into pOptions["user"]
	* put "passw0rd" into pOptions["pass"]

Option 3: use the pOptions parameter with a base 64 encoded username:password, which will be added to the httpheaders:
	* for example, put base64encode("username:password") will yield the string below:
	* put "dXNlcm5hbWU6cGFzc3dvcmQ=" into pOptions["userpasscode"]

Option 4: use cookies/sessions... 
* First  get cookie by posting username and password to sessions
	* put "admin" into pDoc["name"]     
	* put "passw0rd" into pDoc["password"]
   	* put couch.post("session",tURL,,pDoc) into theCookie
* Store it somewhere. For each subsequent call, send theCookie in pOptions
   	* put theCookie into pOptions["cookie"]

Return Format
	* include pOptions["format"] with "array", "rawjson" or "prettyjson" for the return format
	* the stack can have a customProperty called "preferredFormat" which can be one of those three values,
	* if pOptions["format"] is blank, then "preferredFormat" will be used
	* if neither has a value, then "array" will be used


NOTE: a library for decoding and encoding JSON needs to be added, I recommend one of these:
https://github.com/bhall2001/fastjson
https://github.com/luxlogica/easyjson

FUNCTIONS (pFunk)

-----SYSTEM FUNCTIONS-----

GET Function: slash
Returns the welcome message and version information

GET Function: active_tasks	
Obtains a list of the tasks running in the server

GET Function: all_dbs	
Returns a list of all the databases

GET Function: config	
Obtains a list of the entire server configuration
   
GET Function: config
Returns all the configuration values for the specified section
pOptions["section"] contains the section name

GET Function: config
Returns a specific section/configuration value
pOptions["section"] contains the section name
pOptions["key"] contains the configuration key name

PUT Function: config
Sets the specified configuration value
pOptions["section"] contains the section name
pOptions["key"] contains the configuration key name
pOptions["value"] contains the value that the key should be set to

DELETE Function: config
Removes the current setting (dangerous if you don't know what you are doing)
pOptions["section"] contains the section name
pOptions["key"] contains the configuration key name

GET Function: log	
Returns the server log file

POST Function: restart	
Restarts the server

GET Function: stats	
Returns server statistics
 	
GET Function: uuids	
Generates a list of UUIDs from the server
     
-----DATABASE FUNCTIONS-----

GET Function: db
Returns the database information

POST Function: db
Creates a new document with generic ID if he had not specified
pOptions should contain the doc info

PUT Function: db
Creates a new database

DELETE Function: db
Deletes an existing database
 	
GET Function: all_docs	
Returns a built-in view of all documents in this database

POST Function: all_docs	
Returns certain rows from the built-in view of all documents
pDoc["keys"] should be a numbered list of the rows desired
      
POST  Function: bulk_docs	
Inserts or updates multiple documents in to the database in a single request
pDoc should be a numbered array with each number representing a single document

GET Function: changes	
Returns changes for the given database

POST Function: changes
Returns changes for the given database for certain document IDs
pDoc["doc_ids"] should be a numbered list with desired documents
      
POST Function: compact
Starts a compaction for the database

POST Function: compactdesign
Starts a compaction for all the views in the selected design document
pDoc should be the name of the design document
      
POST Function: ensure_full_commit
Makes sure all uncommitted changes are written and synchronized to the disk
      
POST Function: purge
Purges some historical documents entirely from database history
pDoc should be an array, each key is an id number, under each key is a numbered list with rev numbers
     put "c3f2c12bc8c242826e1849097900091d" into tID
     put "4-dc8088c3be9d44b41f87ba1470064672" into tDoc[tID][1]
     put couch.post(purge,tURL,tDB,tDoc)   

GET Function: revs_limit
Returns the limit of historical revisions to store for a single document in the database

PUT Function: revs_limit
Sets the limit of historical revisions to store for a single document in the database
pDoc is a number

GET Function: security
Returns the special security object for the database

PUT Function: security
Sets the special security object for the database
pDoc should contain keys for admins and/or members with subkeyts for names and roles
for example:
     put "uber" into tDoc["admins"]["names"][1]
     put "admins" into tDoc["admins"]["roles"][1]
     put "user" into tDoc["members"]["names"][1]
     put "developer" into tDoc["members"]["roles"][1]
 	
-----DOCUMENT FUNCTIONS-----

GET Function: doc
Returns the document
pDocID is the id of the doc to return

PUT Function: doc
Creates a new document, or new version of an existing document

DELETE Function: doc
Deletes the document
pDocID is the document ID
pParams["rev"] should be the most recent rev number


-----DESIGN DOCUMENT-----

GET Function: design
Returns the design document
pDocID is the name of the design document

PUT Function: design
Creates a new design document, or new version of an existing one
pDoc["_id"] is the name of the design document (unlike regular docs, this must be included)
pDoc["language"] is the programming language being used (most likely javascript)
pDoc["views"] needs to contain a sub key for each view, and each view needs a subkey ["map"] the containts the view doc

GET Function: designinfo
Returns view index information for the specified design document
pDocID is the view document name

GET Function: view
Returns results for the specified stored view
pDocID is the name of the design document with a slash and then the view name
