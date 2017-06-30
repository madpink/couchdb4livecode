constant kURL = "http://127.0.0.1:5984"
constant kAdmin = "YWRtaW46dHJ1c3RubzE="
local sUser, sPass, sAuth

/*
  mp.setUser : put the user's authentication into place
  mp.newUser : creates a new user
  in all commands, if pDB (the database) is not specified, a "user" database is assumed
  
*/

function mp.setUser pUser pPass
   put pUser into sUser
   put pPass into sPass
   put base64encode(pUser & colon & pPass) into sAuth
   return "ok"
end mp.setUser

function mp.alldocs pDB
   put couch.get("all_docs",kURL,mp.userdb(pDB),,,mp.auth()) into tResult
   return  tResult
end mp.alldocs

function mp.putdoc pDoc pDB
   put couch.put("doc",kURL,mp.userdb(pDB),pDoc,,mp.auth()) into tResult
   return tResult
end mp.putdoc

function mp.getdoc pDocID pDB
   put couch.get("doc",kURL,mp.userdb(pDB),pDocID,,mp.auth()) into tResult
   return tResult
end mp.getdoc

function mp.deldoc pDocID pRevID pDB
   put pRevID into tParams["rev"]
   put  couch.delete("doc",kURL,mp.userdb(pDB),pDocID,tParams,mp.auth()) into tResult
   return tResult
end mp.deldoc

function mp.bulkdocs pDB
   --in this command, each doc is include as a seperate parameter
   repeat with x=2 to the paramCount
      put param(x) into tDocs["docs"][x]
   end repeat
   put  couch.post("bulk_docs",kURL,mp.userdb(pDB),tDocs,,mp.auth()) into tResult
   return tResult
end mp.bulkdocs

function mp.bulkdocsarray pDB pArray
   --in this command, pArray includes all of the docs to be uploaded
   put the keys of pArray into tList
   repeat for each line tKey in tList
      add 1 to x
      put pArray[tKey] into tDocs["docs"][x]
   end repeat
   put  couch.post("bulk_docs",kURL,mp.userdb(pDB),tDocs,,mp.auth()) into tResult
   return tResult
end mp.bulkdocsarray

function mp.changes pDB pSince pIncludeDocs
   if pIncludeDocs then put pIncludeDocs into tParams["include_docs"]
   if pSince is not empty then put pSince into tParams["since"]
   put couch.get("changes",kURL,mp.userdb(pDB),,tParams,mp.auth()) into tResult
   return tResult
end mp.changes

function mp.newuser pUser pPass pEmail pCode pName
     put kAdmin into tOptions["authval"]
     put "encoded" into tOptions["authtype"]
     put pEmail into tOptions["registration"]["email"]
     put pName into tOptions["registration"]["name"]
     put pCode into tOptions["registration"]["code"]
     put couch.adduser(kURL,pUser,pPass,tOptions,true) into tResult
     return tResult
end mp.newuser

private function mp.auth
   put sAuth into theOptions["authval"]
   put "encoded" into theOptions["authtype"]
   return theOptions
end mp.auth

private function mp.userdb pDB 
     if pDB is empty or pDB is "user" then put couch.userDB(sUser) into pDB
     return pDB
end mp.userdb

