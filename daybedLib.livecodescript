--name:  libDaybed
--vers:  2.3.1
--date:  2018-11-29
--full:  Daybed - A Library for Apache CouchDB

on ___DaybedDB___
end ___DaybedDB___

/*	
Daybed - A Library for Apache CouchDB
contact:   pink @ mad.pink (aka Greg Miller)
This is a simple library that calls CouchDB's REST functions.
	
---FUNCTION PARAMETERS---

pFunk - (always required) Couch function being called
pURL - (always required) the URL of the CouchDB installation, including "http://", the port numer and a trailing slash
pDB - (required when acting on or retrieving from a database) - the name of the database being accessed
pDocID - (required for most get functions) the document "_id" being retrieved
pDoc - (required for most put and post functions) array containing the data being converted into a document for the database
pParams - an array with any OPTIONAL parameters, with the parameter as a key.
pOptions - (optional) header options, including user and pass (see "Authentication"), also used in "config" operations

Output format:
-include pOptions["format"] with "array", "rawjson" or "prettyjson" for the return format
-the stack can have a customProperty called "preferredFormat" which can be one of those three values,
-if pOptions["format"] is blank, then "preferredFormat" will be used, if it is not set, then "array" will be used
*/

local jsonLibName = fastJSON  --valid values: fastJSON, mergJSON, easyJSON

on ___CouchDB_Main_Functions___
end ___CouchDB_Main_Functions___

function couch.get pFunk pURL pDB pDocID pParams pOptions
   -----  
   local tURL, tResult
   -----
   switch pFunk
      case "db"
         put empty into pDocID
         put empty into pFunk		
         break
      case "localdoc"
         put "_local/" before pDocID
      case "doc"
         put empty into pFunk		
         break
      case "slash"
         put empty into pFunk
         break
      case "ddoc-view"
      case "ddoc-list"
      case "ddoc-show"
      case "ddoc-update"
         put char 6 to -1 of pFunk into pOptions["ddoc"]["func"] 
      case "design"
      case "ddoc"
         put couch.ddoc(pDocID,pOptions) into pDocID
         put empty into pFunk
         break
      case "_config"
      case "config"
         if char 1 of pFunk is not "_" then put "_" before pFunk
         put pOptions["section"] into pDocID
         if pOptions["key"] is not empty then
            put slash & pOptions["key"] after pDocID
         end if
         break
      case "attach"
         put empty into pFunk
         put "/" & pOptions["attachment"] after pDocID
         break
      default
         if char 1 of pFunk is not "_" then put "_" before pFunk
         break
   end switch
   	   		
   couch.setHeaders pOptions
   put couch.DBURL(pURL,pDB,pParams,pFunk,pDocID) into tURL
   
   if pOptions["destination"] is not empty then
      libURLDownloadToFile tURL, pOptions["destination"]
      return "Done"
   else
      put URL(tURL) into tResult
   end if
   	
   return couch.returnFormat(tResult,pOptions["format"])
end couch.get

	
function couch.put pFunk pURL pDB pDoc pParams pOptions
   -----
   local tURL, tResult, tRaw, temp, tFunktion
   -----
   put pFunk into tFunktion
   switch pFunk
      case "db"
         put empty into pDoc
         put empty into pFunk
         break
      case "localdoc"
         put empty into pFunk
         put "_local/" & pDoc["_id"] into pDocID
         break
      case "doc"
         put empty into pFunk
         put pDoc["_id"] into pDocID
         break
      case "attach" 
         put empty into pFunk
         put pOptions["docid"] & "/" & pOptions["attachname"] into pDocID
         break
      case "ddoc-view"
      case "ddoc-list"
      case "ddoc-show"
      case "ddoc-update"
         put char 6 to -1 of pFunk into pOptions["ddoc"]["func"] 
      case "design"
      case "ddoc"
         put pDoc["_id"] into pDocID
         put couch.ddoc(pDocID,pOptions) into pDocID
         put empty into pFunk
         break
      case "_config"
      case "config"
         if char 1 of pFunk is not "_" then put "_" before pFunk
         put pOptions["section"] into pDocID
         if pOptions["key"] is not empty then
            put slash & pOptions["key"] after pDocID
         end if
         break
      case "users"
         put "org.couchdb.user:" & pDoc["name"] into pDocID
         put pDocId into pDoc["_id"]
         put "_users" into pDB
         put empty into pFunk
         break
      default
         if char 1 of pFunk is not "_" then put "_" before pFunk
         break
   end switch
   
   if pOptions["attachments"] is not empty then 
      put couch.attachments(pOptions["attachments"]) into pDoc["_attachments"]
   end if
   
   couch.setHeaders pOptions
   put couch.DBURL(pURL,pDB,pParams,pFunk,pDocID) into tURL
   
   switch tFunktion
      case "db"
         put empty into URL(tURL)
         break
      case "_config"
         put quote & pOptions["value"] & quote into pDoc
         put pDoc into URL(tURL)
         break
      case "_revs_limit"
         put pDoc into URL(tURL)
         break
      case "attach"
         put couch.aType(pOptions["attachmode"],pOptions["attachpath"]) into tPath
         put URL(tPath) into URL(tURL)
         break
      default
         put a2j(pDoc) into tJson
         replace "[null]" with "[]" in tJson
         put tJson into URL(tURL)
         break
   end switch
   put the urlResponse into tResult
   return couch.returnFormat(tResult,pOptions["format"])
end couch.put

	
function couch.post pFunk pURL pDB pDoc pParams pOptions 
   -----
   local tURL, tResult, tJson
   -----
   switch pFunk
      case "db"
         put empty into pFunk
         break
      case "changes"
         put "_doc_ids" into pParams["filter"]
         break
      case "compactdesign"
         put "_compact" into pFunk
         put pDoc into pDocID
         break
      case "ddoc-view"
      case "ddoc-list"
      case "ddoc-show"
      case "ddoc-update"
         put char 6 to -1 of pFunk into pOptions["ddoc"]["func"] 
      case "design"   
      case "ddoc"
         put pDoc["_id"] into pDocID
         put couch.ddoc(pDocID,pOptions) into pDocID
         put empty into pFunk
         break
      default
         if char 1 of pFunk is not "_" then put "_" before pFunk
         break
   end switch
   	   	
   couch.setHeaders pOptions
   put a2j(pDoc) into tJson
   put couch.DBURL(pURL,pDB,pParams,pFunk,pDocID) into tURL
   post tJson to URL(tURL)
   put the urlResponse into tResult
   switch pFunk
      case "_session"
         return couch.cookie(tResult)
         break
      default
         return couch.returnFormat(tResult,pOptions["format"])
         break
   end switch
end couch.post
		
function couch.delete pFunk pURL pDB pDocID pParams pOptions 
   -----
   local tURL, tResult
   -----
   switch pFunk
      case "db"
         put empty into pDocID
         put empty into pFunk
         break
      case "attach"
         put empty into pFunk
         put "/" & pOptions["attachment"] after pDocID
         break	
      case "doc"
         put empty into pFunk
         break
      case "localdoc"
         put empty into pFunk
         put "_local/" before pDocID
         break
      default
         if char 1 of pFunk is not "_" then put "_" before pFunk
         break
   end switch
   couch.setHeaders
   put couch.DBURL(pURL,pDB,pParams,pFunk,pDocID) into tURL
   delete URL(tURL)
   put the urlResponse into tResult
   return couch.returnFormat(tResult,pOptions["format"])
end couch.delete

function couch.adduser pURL pUser pPass pOptions 
   -----
   local tResult
   local tReturnFormat,tUser
   -----
   
   put pOptions["format"] into tReturnFormat
   put "json" into pOptions["format"]
   put pUser into tUser["name"]
   put pPass into tUser["password"]
   put "user" into tUser["type"]
   if pOptions["roles"] is not empty then
      put pOptions["roles"] into tUser["roles"] 
   else
      put empty into tUser["roles"][1]
   end if
   if pOptions["userdata"] is not empty then put pOptions["userdata"] into tUser["userdata"]
   if pOptions["registration"] is not empty then put pOptions["registration"] into tUser["registration"]
   put couch.put("users",pURL,,tUser,,pOptions) into tResult
   return couch.returnFormat(tResult,tReturnFormat)
end couch.adduser

function couch.securedb pFunk pURL pDB pOptions pAdminNames pAdminRoles pMemberNames pMemberRoles
   -----
   local returnFormat,tSecurity
   local tResult
   -----
   
   put pOptions["format"] into returnFormat
   put "json" into pOptions["format"]
   
   switch pFunk
      case "set"
      case "replace"
         put "_security" into tSecurity["_id"]
         put c2a(pAdminNames) into tSecurity["admins"]["names"]
         put c2a(pAdminRoles)into tSecurity["admins"]["roles"]
         put c2a(pMemberNames) into tSecurity["members"]["names"]
         put c2a(pMemberRoles) into tSecurity["members"]["roles"]
         put couch.put("doc",pURL,pDB,tSecurity,,pOptions) into tResult
         break
      case "get"
         put couch.get("doc",pURL,pDB,"_security",,pOptions) into tResult
         break
      case "add"
         put "array" into pOptions["format"]
         put couch.get("doc",pURL,pDB,"_security",,pOptions) into tSecurity
         put "_security" into tSecurity["_id"]
         put add2list(pAdminNames,tSecurity["admins"]["names"]) into tSecurity["admins"]["names"]
         put add2list(pAdminRoles,tSecurity["admins"]["roles"]) into tSecurity["admins"]["roles"]
         put add2list(pMemberNames,tSecurity["members"]["names"]) into tSecurity["members"]["names"]
         put add2list(pMemberRoles,tSecurity["members"]["roles"]) into tSecurity["members"]["roles"]
         put "json" into pOptions["format"]
         put couch.put("doc",pURL,pDB,tSecurity,,pOptions) into tResult
         break
      case "remove"
      case "delete"
         put "array" into pOptions["format"]
         put couch.get("doc",pURL,pDB,"_security",,pOptions) into tSecurity
         put "_security" into tSecurity["_id"]
         put delFromlist(pAdminNames,tSecurity["admins"]["names"]) into tSecurity["admins"]["names"]
         put delFromlist(pAdminRoles,tSecurity["admins"]["roles"]) into tSecurity["admins"]["roles"]
         put delFromlist(pMemberNames,tSecurity["members"]["names"]) into tSecurity["members"]["names"]
         put delFromlist(pMemberRoles,tSecurity["members"]["roles"]) into tSecurity["members"]["roles"]
         put "json" into pOptions["format"]
         put couch.put("doc",pURL,pDB,tSecurity,,pOptions) into tResult
         break
   end switch
   return couch.returnFormat(tResult,returnFormat)
end couch.securedb

on ___CouchDB_Quick_Functions___
end ___CouchDB_Quick_Functions___

local sCouchURL = "http://127.0.0.1:5984"
local sDatabase = "test"
local sAuthentication = ""

command qouch.init pDB pUser pPass pURL
   if pURL is not empty then put pURL into sCouchURL
   if pDB is not empty then 
      if char -1 of pDB is "_" then 
         put couch.userDB(pUser,pDB) into sDatabase
      else
         put pDB into sDatabase
      end if
   end if
   if pUser is not empty then put base64encode(pUser & colon & pPass) into sAuthentication
end qouch.init

private function qouch.auth
   local tOptions
   put sAuthentication into tOptions["authval"]
   put "encoded" into tOptions["authtype"]
   return tOptions
end qouch.auth

function qouch.getdoc pDocID pParams
   return couch.get("doc",sCouchURL,sDatabase,pDocID,qouch.auth(),pParams)
end qouch.getdoc

function qouch.putdoc pDoc pParams
   return couch.put("doc",sCouchURL,sDatabase,pDoc,qouch.auth(),pParams)
end qouch.putdoc

function qouch.alldocs pInclude pParams
   --if pInclude then put true into pCDB["params"]["include_docs"]
   if pInclude then put true into pParams["include_docs"]
   return couch.get("all_docs",sCouchURL,sDatabase,,pParams,qouch.auth())
end qouch.alldocs

function qouch.changes pLast pInclude pParams
   if pLast is not empty then put pLast into pCDB["params"]["since"]
   if pInclude then put true into pCDB["params"]["include_docs"]
   return couch.get("changes",sCouchURL,sDatabase,,qouch.auth(),pParams)
end qouch.changes

function qouch.ddoc pDdoc pType pName pInclude pParams
   if pInclude then put true into pCDB["params"]["include_docs"]
   put pType into pCDB["options"]["ddoc"]["func"]
   put pName into pCDB["options"]["ddoc"]["xtend"]
   put couch.get("design",sCouchURL,sDatabase,pDdoc,qouch.auth(),pParams)
end qouch.ddoc

on ___CouchDB_Experimental_Functions___
end ___CouchDB_Experimental_Functions___

command couch.db.example
   local tCouch, tResults
   
   put "get" into tCouch["verb"]
   put "192.168.23.42:5984" into tCouch["url"]
   put "doc" into tCouch["funk"]
   put "rec541" into tCouch["docid"]
   put "admin" into tCouch["options"]["user"]
   put "trustno1" into tCouch["options"]["pass"]
   
   put couch.db(tCouch) into tResults
end couch.db.example

function couch.db pCouch  ---This is an experimental UberFunction
  /* 
  pCouch["verb"]
  pCouch["url"]
  pCouch["funk"]
  pCouch["options"]
  pCouch["params"]
  pCouch["doc"]
  pCouch["docid"]
  */
  -----
  local tFormat, tResult
  -----
  put pCouch["options"]["format"] into tFormat
  
  if pCouch["load"] is not empty then put dbdb.useSavedCouch(pCouch) into pCouch
  
  put "json" into pCouch["options"]["format"]
  switch pCouch["verb"]
    case "get"
      put couch.get(pCouch["funk"],pCouch["url"],pCouch["db"],pCouch["docid"],pCouch["params"],pCouch["options"]) into tResult
      break
    case "put"
      put couch.put(pCouch["funk"],pCouch["url"],pCouch["db"],pCouch["doc"],pCouch["params"],pCouch["options"]) into tResult
      break
    case "post"
      put couch.post(pCouch["funk"],pCouch["url"],pCouch["db"],pCouch["doc"],pCouch["params"],pCouch["options"]) into tResult
      break
    case "delete"
      put couch.delete(pCouch["funk"],pCouch["url"],pCouch["db"],pCouch["docid"],pCouch["params"],pCouch["options"]) into tResult
      break
    case "adduser"
      put  couch.adduser(pCouch["url"],pCouch["user"],pCouch["pass"],pCouch["options"],pCouch["addDB"]) into tResult
      break
    case "securedb"
      put couch.securedb(pCouch["funk"],pCouch["url"],pCouch["db"],pCouch["adminnames"],pCouch["adminroles"],pCouch["membernames"],pCouch["memberroles"]) into tResult
      break
  end switch
  return couch.returnFormat(tResult,tFormat)
end couch.db



function couch.userDB pUsername pPrefix
  -----
  local tDBName, tUser
  -----
  if pPrefix is empty then 
    put "user_" into tDBName
  else
       put pPrefix into tDBName
       if char -1 of tDBName is not "_" then  put "_" after tDBName
  end if
  
  get binarydecode("H*",pUsername,tUser)
  put tUser after tDBName
  replace return with empty in tDBName
  
  return tDBName
end couch.userDB

on ___DaybedDB_LocalProp_Sync__
end ___DaybedDB_LocalProp_Sync__

function dbdb.local.newuser pURL pUser pPass pAuth pPrefix pOther pConflict pIDPrefix pApp pPurge pType
  /*    pURL - full URL including port
  pPrefix - prefix of the db name (e.g. "user", "mppb")
  pUser - username    pPass - password
  pOther - (optional) array of other data to be saved in _users
  pConflict - (optional - defaults to server) local, server, duplicate  
  pAuth - (optional if "Admin party" is in effect) the admin authorization string 
  pIDPrefix - (optional) prefix for id numbers based on milliseconds 
  
  for userDB:
  pApp - (optional for userdb) application name for searches 
  for appDB:
  pApp - application db name
  
  pPurge - (optional) how often to purge deleted docs  */
  -----
  local tSettings
  -----
  set the customPropertySet of this stack to "daybedDB"
  
  if pType is "appdb" then
    put dbdb.appdb.createuser(pURL,pApp,pUser,pPass,pConflict,pAuth,pOther,pPurge) into tSettings
  else
    put dbdb.userdb.createuser(pURL,pPrefix,pUser,pPass,pConflict,pAuth,pOther,pIDPrefix,pApp,pPurge) into tSettings
  end if
  
  set the "_dbdbsettings" of this stack to tSettings["dbdb"]
  return tSettings
end dbdb.local.newuser

command dbdb.local.setting pSett pVal 
     ---
     local tSettings
     ---
     set the customPropertySet of this stack to "daybedDB"
     put the _dbdbsettings of this stack into tSettings
     put pVal into tSettings[pSett]
     set the _dbdbsettings of this stack to tSettings
end dbdb.local.setting

command dbdb.local.sync
  ------
  local currentData, revisedData, tResult
  ------
  put the customProperties["daybedDB"] of this stack into currentData
  if currentData["_dbdbsettings"] is empty then 
    put "Error: Not setup, run dbdb.newuser" into tResult["errorcode"]
    put true into tResult["error"]
    return tResult
  end if
  put dbdb.sync(currentData) into revisedData
  if not revisedData["error"] then 
    set the customProperties["daybedDB"] of this stack to revisedData
    put true into tResult["ok"]
    return tResult
  else
    return revisedData
  end if
end dbdb.local.sync

command dbdb.local.setdoc pDoc pDelete
  -----
  local tID, tSett
  -----
  put the daybedDB["_dbdbsettings"] of this stack into tSett
  if pDoc["_id"] is empty then put dbdb.newdocid(tSett) into pDoc["_id"]
  put pDoc["_id"] into tID
  put the seconds into pDoc["dbdb"]["lastupdated"]
  put tSett["appname"] into pDoc["dbdb"]["app"]
  if pDoc["_rev"] is not empty then
    put "update" into pDoc["dbdb"]["flag"]
  else 
    put "new" into pDoc["dbdb"]["flag"]
    put 0 into pDoc["dbdb"]["lastsync"]
  end if
  put tSett["idprefix"] & pDoc["dbdb"]["lastsync"] into pDoc["dbdb"]["syncid"]
  set the daybedDB[tID] of this stack to pDoc
end dbdb.local.setdoc

command dbdb.local.deletedoc pDocID
  -----
  local tDoc
  -----
  put the daybedDB[pDocID] of this stack into tDoc
  put "delete" into tDoc["dbdb"]["flag"]
  put the seconds into pDoc["dbdb"]["lastupdated"]
  set the daybedDB[pDocID] of this stack to tDoc
end dbdb.local.deletedoc

function dbdb.local.getdoc pDocID
  return the daybedDB[pDocID] of this stack
end dbdb.local.getdoc

on ___DaybedDB_Local_Stack
end ___DaybedDB_Local_Stack

command dbdb.stack.load pFileName pStackName pMainFolder pSubFolder pPropSet
  -----
  local tData
  -----
  if pPropSet is empty then put "daybedDB" into pPropSet
  if pStackName is empty then put the short name of this stack & "_data"  into pStackName
  put getFilePath(pMainFolder,pSubFolder,pFileName) into pFileName
  if pStackName is not among the lines of the mainStacks then
    if there is no file pFileName then 
      create invisible stack pStackName
      save stack pStackName as pFileName
      return true
    else
      open invisible stack pFileName
      put the customProperties[pPropSet] of stack pStackName into tData
      set the customproperties["daybedDB"] of this stack to tData
    end if
  end if
end dbdb.stack.load

command dbdb.stack.save pStackName pPropSet
     -----
     local tData
     -----
     if pPropSet is empty then put "daybedDB" into pPropSet
     if pStackName is empty then put the short name of this stack & "_data" into pStackName
     put the customproperties["daybedDB"] of this stack into tData
     set the customProperties["pPropSet"] of stack pStackName to tData
     save stack pStackName
end dbdb.stack.save

on ___DaybedDB_Local_File
end ___DaybedDB_Local_File

command dbdb.file.load pFileName pMainFolder pSubFolder
  -----
  local tData
  -----
  if pFileName is empty then put the short name of this stack & "_data"  into pFileName
  put getFilePath(pMainFolder,pSubFolder,pFileName) into pFileName
  if there is a file pFilePath then 
    put URL("binfile:" & pFileName) into tData
    set the customproperties["daybedDB"] of this stack to arrayDecode(tData)
  end if
end dbdb.file.load

command dbdb.file.save pFileName pMainFolder pSubFolder
  -----
  local tData
  -----
  if pFileName is empty then put the short name of this stack & "_data" into pFileName
  put getFilePath(pMainFolder,pSubFolder,pFileName) into pFileName
  put the customproperties["daybedDB"] of this stack into tData
  
  put arrayEncode(tData) into URL("binfile:" & pFileName)
end dbdb.file.save

on ___DaybedDB_Local_JSON_File
end ___DaybedDB_Local_JSON_File

command dbdb.json.load pFileName pMainFolder pSubFolder
  -----
  local tData
  -----
  if pFileName is empty then put the short name of this stack & "_data"  into pFileName
  put getFilePath(pMainFolder,pSubFolder,pFileName) into pFileName
  if there is a file pFileName then 
    put URL("file:" & pFileName) into tData
    set the customproperties["daybedDB"] of this stack to j2a(tData)
  end if
end dbdb.json.load

command dbdb.json.save pFileName pMainFolder pSubFolder
  -----
  local tData
  -----
  if pFileName is empty then put the short name of this stack & "_data" into pFileName
  put getFilePath(pMainFolder,pSubFolder,pFileName) into pFileName
  put the customproperties["daybedDB"] of this stack into tData
  
  put a2j(tData,,true) into URL("file:" & pFileName)
end dbdb.json.save


on ___DaybedDB_User_Functions__
end ___DaybedDB_User_Functions__

function dbdb.appdb.createdb pURL pDB pAuth
  -----
  local tResult
  -----
  if pAuth is not empty then 
    put pAuth into tOptions["authval"]
    put "encoded" into tOptions["authtype"]
  end if
  put couch.put("db",pURL,PDB,,,tOptions) into tResult["db"]
  put couch.put("doc",pURL,tSettings["db"],dbdb.appdbdesigndoc(),,tOptions) into tResult["ddoc"]
  return tResult
end dbdb.appdb.createdb

function dbdb.appdb.createuser pURL pDB pUser pPass pConflict pAuth pOther pPurge
  ------ 
  local tOptions, tSettings, tUser, tResult
  ------
  if pAuth is not empty then 
    put pAuth into tOptions["authval"]
    put "encoded" into tOptions["authtype"]
  end if
  put urlencode(pUser) into pUser
  
  ---create Settings
  put "appdb" into tSettings["type"]
  put pURL into tSettings["url"]
  put pDB into tSettings["db"]
  put pAuth into tSettings["auth"]
  put 0 into tSettings["lastsync"]
  put czVal(pConflict,"server") into tSettings["conflict"]
  put pUser into tSettings["idprefix"]
  put czVal(pPurge,30) into tSettings["purge"]
  put encodeUserPass(pUser,pPass) into tSettings["userauth"]
  put "dbdbid_" & pUser into tSettings["userdoc"]
  put pOther into tSettings["userdata"]
  
  ---create User Doc
  put "dbdbid_" & pUser into tUser["_id"]
  put the seconds into tUser["datestamp"]
  put encodeUserPass(pUser,pPass,tUser["datestamp"]) into tUser["userauth"]
  put pOther into tUser["userdata"]
  put couch.put("doc",pURL,pDB,tUser,tOther) into tResult
  
  if tResult["ok"] is not true and tResult["error"] is "conflict" then
    put dbdb.appdb.login(tSettings) into tResult
    
    if tResult["reason"] is "login_failed" then 
      put empty into tSettings
      put true into tSettings ["error"]
      put "user_exists" into tSettings["reason"]
    else
      put tResult["_rev"] into tSettings["userrev"]
    end if
    
  else
    put tResult["rev"] into tSettings["userrev"]
  end if
  
  return tSettings
end dbdb.appdb.createuser

function dbdb.appdb.login pSett
  ---
  local tResult, tOptions
  ---
  if pAuth is not empty then 
    put pSett["auth"] into tOptions["authval"]
    put "encoded" into tOptions["authtype"]
  end if
  
  put couch.get("doc",pSett["url"],pSett["db"],pSett["userdoc"],tOptions) into tResult
  if tResult["userauth"] is not pSett["userauth"] then
    put empty into tResult
    put true into tResult["error"]
    put "login_failed" into tResult["reason"]
  end if
  
  return tResult
end dbdb.appdb.login

function dbdb.userdb.createuser pURL pPrefix pUser pPass pConflict pAuth pOther pIDPrefix pAppName pPurge
  ------ 
  local tOptions, tSettings, tResult
  ------
  if pAuth is not empty then 
    put pAuth into tOptions["authval"]
    put "encoded" into tOptions["authtype"]
  end if
  
  put couch.authval(pUser,pPass) into tSettings["auth"]
  
  get binarydecode("H*",pUser,tSettings["db"])
  put czVal(pPrefix,"user") & "_" before tSettings["db"]
  
  put pURL into tSettings["url"]
  put 0 into tSettings["lastsync"]
  put "userdb" into tSettings["type"]
  put czVal(pConflict,"server") into tSettings["conflict"]
  put czVal(pIDPrefix,"user") into tSettings["idprefix"]
  put czVal(pAppName,tSettings["idprefix"]) into tSettings["appname"]
  put czVal(pPurge,30) into tSettings["purge"]
  put pOther into tSettings["userdata"]
  
  put tSettings into tResult["dbdb"]
  
  put pOther into tOptions["userdata"]
  
  put couch.adduser(pURL,pUser,pPass,tOptions) into tResult["user"]
  put couch.put("db",pURL,tSettings["db"],,,tOptions) into tResult["db"]
  
  put couch.put("doc",pURL,tSettings["db"],dbdb.appdesigndoc(tSettings["appname"]),,tOptions) into tResult["ddoc"]
  
  put couch.securedb("set",pURL,tSettings["db"],tOptions,pUser,,pUser) into tResult["security"]
  return tResult
end dbdb.userdb.createuser

on ___DaybedDB_Sync_Functions__
end ___DaybedDB_Sync_Functions__

function dbdb.sync pArray pForceFull
  /*
  Settings are passed in pArray["_dbdbsettings"]
  */
  --TODO: add audit trail with revision numbers and timestamps?
  -----
  local tKey, dbName, dbURL, dbDdoc, tOptions, tParams
  local upList, upDocs, downList, downDocs
  local tempID, tRevS, tRevL, tCnt
  -----
  put pArray["_dbdbsettings"]["lastsync"] into tParams["startkey"]
  put the seconds into syncTime
  put syncTime into pArray["_dbdbsettings"]["lastsync"]
  
  put pArray["_dbdbsettings"]["db"] into dbName
  put pArray["_dbdbsettings"]["url"] into dbURL
  put pArray["_dbdbsettings"]["auth"] into tOptions["authval"]
  put "encoded" into tOptions["authtype"]
  
  --scan local data for flagged changes and copy into upDocs
  repeat for each key tKey in pArray
    if char 1 of tKey is "_" then next repeat
    if pArray[tKey]["dbdb"]["flag"] is empty or pArray[tKey]["dbdb"]["flag"] is "synced" then next repeat
    if pArray[tKey]["dbdb"]["flag"]  is "delete" then put true into pArray[tKey]["dbdb"]["deleted"]
    if pArray[tKey]["dbdb"]["deleted"] then put "delete" into pArray[tKey]["dbdb"]["flag"]
    put pArray["_dbdbsettings"]["lastsync"] into pArray[tKey]["dbdb"]["lastsync"]
    put empty into pArray[tKey]["dbdb"]["flag"]
    put pArray[tKey] into upDocs["docs"][tKey]
    if pArray[tKey]["_delete"] then delete variable pArray[tKey]
  end repeat
  
  --download list with ddoc using synctime as key filter
  if pArray["_dbdbsettings"]["type"] is "appdb" then
    put "daybedusers" into dbDdoc
  else
    put "daybed" & pArray["_dbdbsettings"]["appname"] into dbDdoc
  end if
  put "view" into tOptions["ddoc"]["func"]
  put "app" into tOptions["ddoc"]["name"]
  put couch.get("design",dbURL,dbName,dbDdoc,tParams,tOptions) into downList
  
  --scan change log, record by record
  repeat for each key tKey in downList["rows"]
    put downList["rows"][tKey]["value"]["id"] into tempID
    
    --for later, we'll double check that all documents are on server
    put tempID & cr after downlist["idlist"]
    
    --skip documents not related if applicable
    if pArray["_dbdbsettings"]["idprefix"] is not empty and pArray["_dbdbsettings"]["idprefix"] is not "uuid" then
      if not(tempID begins with pArray["_dbdbsettings"]["idprefix"]) then next repeat
    end if
    
    --delete documents locally that have been deleted on the server
    if downList["rows"][tKey]["value"]["deleted"]  then
      delete variable pArray[tempID]
      next repeat
    end if
    
    --if document doesn't exist locally, flag it for download
    if pArray[tempID] is empty then
      put tempID into downDocs["keys"][tKey]
      next repeat
    end if
    
    --compare revision numbers
    set itemdel to "-"
    put item 1 of downList["rows"][tKey]["value"]["rev"] into tRevS
    put item 1 of pArray[tempID]["_rev"] into tRevL
    
    if tRevL = tRevS then next repeat
    
    if tRevL > tRevS then
      --This shouldn't happen
      --This resets the revID and reuploads the doc
      --Unless it is already flagged for upload, in which case rev is updated
      if upDocs[tempID] is empty then
        put pArray[tempID] into upDocs["docs"][tempID]
        put downList["rows"][tKey]["value"]["rev"] into upDocs["docs"][tempID]["_rev"]
      else if pArray[tempID] is not empty then
        put downList["rows"][tKey]["value"]["rev"] into pArray[tempID]["_rev"]
      end if
      next repeat
    end if
    
    if tRevL < tRevS then
      --If the local doc hasn't been updated, it will be updated
      if upDocs["docs"][tempID] is empty then 
        put tempID into downDocs["keys"][tKey]
        next repeat
      end if
      
      put "server" into pArray["_dbdbsettings"]["conflict"]
      
      --if the local doc has been updated and the server doc has been updated:
      switch pArray["_dbdbsettings"]["conflict"]
        case "local"
          put downList["rows"][tKey]["value"]["rev"] into upDocs["docs"][tempID]["_rev"]
          break
        case "server"
          put tempID into downDocs["keys"][tKey]
          break
        case "duplicate"
          put tempID into downDocs["keys"][tKey]
          delete variable upDocs["docs"][tempID]
          put dbdb.newdocid() into tNewID
          put pArray[tempID] into upDocs["docs"][tNewID]
          put pArray[tempID] into pArray[tNewID]
          delete variable upDocs["docs"][tNewID]["_rev"]
          break
      end switch
    end if
  end repeat
  
  --doublecheck that all local files are on server
  repeat for each key tKey in pArray
    if char 1 of tKey is "_" then next repeat
    if tKey is among the lines of downList["idlist"] then next repeat
    if pArray["_dbdbsettings"]["lastsync"] is not empty then next repeat
    put pArray[tKey] into upDocs["docs"][tKey]
  end repeat
  
  --upload local docs that are new or have been modified
  if upDocs["docs"] is not empty then
    put jsonArrayMaker(upDocs["docs"]) into upDocs["docs"]
    put couch.post("bulk_docs",dbURL,dbName,upDocs,tParams,tOptions) into upList
    repeat for each key tKey in upList
      put upList[tKey]["id"] into tempID
      if pArray[tempID]["_deleted"] then
        delete variable pArray[tempID]
      else
        put upList[tKey]["rev"] into pArray[tempID]["_rev"]
      end if
    end repeat
  end if
  
  --download server docs that are new or have been modified
  if downDocs["keys"] is not empty then
    put empty into tParams
    put true into tParams["include_docs"]
    put jsonArrayMaker(downDocs["keys"]) into downDocs["keys"]
    put couch.post("all_docs",dbURL,dbName,downDocs,tParams,tOptions) into downList
    repeat for each key tKey in downList["rows"]
      put downList["rows"][tKey]["id"] into tempID
      put downList["rows"][tKey]["doc"] into pArray[tempID]
    end repeat
  end if
  
  delete variable pArray[empty]
  
  repeat for each key tKey in pArray
    if char 1 of tKey is "_" then next repeat
    put "synced" into pArray[tKey]["dbdb"]["flag"]
  end repeat
  
  return pArray
end dbdb.sync

command dbdb.purge pSettings
  --TODO: add purge function
  local tOptions, tParams, tKey, purgeList, purgeDocs
  ---
  put the seconds - (pSettings["purge"] * 86400) into tOptions["endkey"]
  put "purge" into tOptions["ddoc"]["name"]
  put "encoded" into tOptions["authtype"]
  put pSettings["auth"] into tOptions["authval"]
  
  put couch.get("ddoc-view",pSettings["url"],pSettings["db"],("daybed" & pSettings["appname"]),tParams,tOptions) into purgeList
  
  if purgeList["rows"] is empty then exit dbdb.purge
  
  repeat for each key tKey in purgeList["rows"]
    put purgeList["rows"][tKey]["value"]["id"] into purgeDocs["docs"][tKey]["_id"]
    put purgeList["rows"][tKey]["value"]["rev"] into purgeDocs["docs"][tKey]["_rev"]
    put true into purgeDocs["docs"][tKey]["_deleted"]
  end repeat
  
  put couch.post("bulk_docs",pSettings["url"],pSettings["db"],purgeDocs,tParams,tOptions) into upList
end dbdb.purge

function dbdb.newdocid pSettings
   -----
   local tNewID
   -----
   if pSettings is empty then put the daybedDB["_dbdbsettings"] of this stack into pSettings
   if pSettings["idprefix"] is empty then
      put "db_" into tNewID
   else if pSettings["idprefix"] is "uuid" then
     return uuid("random")
   else
     put pSettings["idprefix"] into tNewID
     if char -1 of tNewID is not "_" then put "_" after tNewID
   end if
   put (the seconds - 979668822) after tNewID
   return tNewID
end dbdb.newdocid

function dbdb.appdbdesigndoc
  local tDDoc
  -----
  put "_design/daybed" & pAppName into tDDoc["_id"]
  
  put "function (doc) { emit(doc.dbdb.syncid,{" into tDDoc["views"]["app"]["map"]
  put quote & "app" & quote & colon & "doc.dbdb.app" & comma  after tDDoc["views"]["app"]["map"]
  put quote & "id" & quote & colon & "doc._id" & comma  after tDDoc["views"]["app"]["map"]
  put quote & "deleted" & quote & colon & "doc.dbdb.deleted" & comma  after tDDoc["views"]["app"]["map"]
  put quote & "rev" & quote & colon & "doc._rev" after tDDoc["views"]["app"]["map"]
  put "});}"  after tDDoc["views"]["app"]["map"]
  
  put "function (doc) { if(doc.dbdb.deleted == true) emit(doc.dbdb.syncid,{" into tDDoc["views"]["purge"]["map"]
  put quote & "app" & quote & colon & "doc.dbdb.app" & comma  after tDDoc["views"]["purge"]["map"]
  put quote & "id" & quote & colon & "doc._id" & comma  after tDDoc["views"]["purge"]["map"]
  put quote & "deleted" & quote & colon & "doc.dbdb.deleted" & comma  after tDDoc["views"]["purge"]["map"]
  put quote & "rev" & quote & colon & "doc._rev" after tDDoc["views"]["purge"]["map"]
  put "});}"  after tDDoc["views"]["purge"]["map"]
  
  put sVersion into tDDoc["version"]
  put "javascript" into tDDoc["language"]
  return tDDoc
end dbdb.appdbdesigndoc

function dbdb.appdesigndoc pAppName
   local tDDoc, tApp
   ------
   put "_design/daybed" & pAppName into tDDoc["_id"]
   put quote & pAppName & quote into tApp
   put "function (doc) { if(doc.dbdb.app == " & quote & pAppName & quote & ") emit(doc.dbdb.lastsync,{" into tDDoc["views"]["app"]["map"]
   put quote & "app" & quote & colon & "doc.dbdb.app" & comma  after tDDoc["views"]["app"]["map"]
   put quote & "id" & quote & colon & "doc._id" & comma  after tDDoc["views"]["app"]["map"]
   put quote & "deleted" & quote & colon & "doc.dbdb.deleted" & comma  after tDDoc["views"]["app"]["map"]
   put quote & "rev" & quote & colon & "doc._rev" after tDDoc["views"]["app"]["map"]
   put "});}"  after tDDoc["views"]["app"]["map"]
   
   put "function (doc) { if(doc.dbdb.app ==" && quote & pAppName & quote && "& doc.dbdb.deleted == true) emit(doc.dbdb.lastsync,{" into tDDoc["views"]["purge"]["map"]
   put quote & "app" & quote & colon & "doc.dbdb.app" & comma  after tDDoc["views"]["purge"]["map"]
   put quote & "id" & quote & colon & "doc._id" & comma  after tDDoc["views"]["purge"]["map"]
   put quote & "deleted" & quote & colon & "doc.dbdb.deleted" & comma  after tDDoc["views"]["purge"]["map"]
   put quote & "rev" & quote & colon & "doc._rev" after tDDoc["views"]["purge"]["map"]
   put "});}"  after tDDoc["views"]["purge"]["map"]

   put sVersion into tDDoc["version"]
   put "javascript" into tDDoc["language"]
   return tDDoc
end dbdb.appdesigndoc

on ___CouchDB_Internal_Functions___
end ___CouchDB_Internal_Functions___

private function getFilePath pMainFolder pSubFolder pFileName
  -----
  local tPathName
  ------
  if pMainFolder is empty then
    switch the platform
      case "Win32"
      case  "MacOS"
        put "support" into pMainFolder
        break
      case "iphone"
      case "android"
        put "documents" into pMainFolder
        break
      case "Linux"
      case "HTML5"
        put "home" into pMainFolder
        break
    end switch
  end if
  switch pMainFolder
    case "desktop"
    case "desk"
      put (specialfolderpath("Desktop")) into tPathName
      break
    case "doc"
    case "docs"
    case "documents"
      put (specialfolderpath("documents")) into tPathName
      break
    case "support"
      put (specialfolderpath("support")) into tPathName
      break
    default 
      put pMainFolder into tPathName
  end switch
  if pSubFolder is empty then 
    put "/" & the short name of this stack after tPathName
  else
    put "/" & pSubFolder after tPathName
  end if
  
  if there is no folder tPathName then create folder tPathName
  
  if pFileName is empty then 
    put "/" & the short name of this stack & ".dbdb" after tPathName
  else
    put "/" & pFileName after tPathName
  end if
  
  return tPathName
end getFilePath

function encodeUserPass pUser pPass pApp
  ---
  local tString
  ---
  encrypt pUser & ":" & pPassword & "@" & pApp using "aes-256-cbc" with key "+(011)-8-999-88199-9119-725----3" at 256 bit
  put base64encode(it) into tString
  return tString
end encodeUserPass

function couch.authval pUser pPass
  local tAuthVal
  put base64encode(pUser & ":" & pPass) into tAuthVal
  return tAuthVal
end couch.authval

private function couch.attachments pAtt
  -----
  local tFileName,tFilePath,tAttachMe
  -----
  
  repeat for each key tFile in pAtt
    put tFile into tFileName
    switch pAtt[tFile]["mode"]
      case "ascii"
      case "text"
        put "file:" &  pAtt[tFile]["path"] into tFilePath
        break
      default
        put "binfile:" &  pAtt[tFile]["path"] into tFilePath
        break
    end switch
    
    if pAtt[tFile]["mime"] is empty then
      put contentTypeCheck(tFile,pAtt[tFile]["mode"]) into tAttachMe[tFileName]["content_type"]
    else
      put pAtt[tFile]["mime"] into tAttachMe[tFileName]["content_type"]
    end if
    
    put base64encode(url (tFilePath)) into tAttachMe[tFileName]["data"]
  end repeat
  return tAttachMe
end couch.attachments

private function couch.aType pType pPath
  switch pType
    case "bin"
    case "binary"
      put "binfile:" & pPath into pPath
      break
    case "text"
    case "ascii"
    default
      put "file:" & pPath into pPath
      break
  end switch
  return pPath
end couch.aType

private function couch.ddoc pDocID pOptions
  if pDocID is empty then put pOptions["docid"] into pDocID
  if char 1 to 7 of pDocID is not "_design" then put "_design/" before pDocID
  if pOptions["ddoc"]["func"] is not empty then 
    if char 1 of pOptions["ddoc"]["func"] is not "_" then put "_" before pOptions["ddoc"]["func"]
    put "/" & pOptions["ddoc"]["func"] after pDocID
  end if
  if pOptions["ddoc"]["name"] is not empty then put "/" & pOptions["ddoc"]["name"] after pDocID
  if pOptions["ddoc"]["otherid"] is not empty then put "/" & pOptions["ddoc"]["otherid"] after pDocID
  if pOptions["ddoc"]["otherfunc"] is not empty then put "/" & pOptions["ddoc"]["otherfunc"] after pDocID
  if pOptions["attachment"] is not empty then put "/" & pOptions["attachment"] after pDocID
  return pDocID
end couch.ddoc

private function couch.cookie pResult
  -----
  local tResponse, tLine, tCookie, tReturnHeaders
  -----
  put j2a(pResult) into tResponse
  if tResponse["ok"] is not true then return "ERROR"
  put libURLLastRHHeaders() into tReturnHeaders
  repeat for each line tLine in tReturnHeaders
    if tLine begins with "Set-Cookie" then
      set itemdel to ";"
      put item 1 of tLine into tLine
      set itemdel to "="
      put item 2 of tLine into tCookie
      return tCookie
    end if
  end repeat
end couch.cookie

private command couch.setHeaders pOptions
  -----
  local couchHeaders
  -----
  if pOptions["attachname"] is empty then 
    put "Accept: application/json, text/plain, text/event-stream"&cr into couchHeaders
    put "Content-Type: application/json" after couchHeaders
  else if pOptions["attachtype"] is empty then
    put "Content-Type:"&&contentTypeCheck(pOptions["attachname"],pOptions["attachmode"]) into couchHeaders -- pOptions["attachtype"] 
  else
    put "Content-Type:"&&pOptions["attachtype"] into couchHeaders
  end if
  switch pOptions["authtype"]
    case "encoded"
      put "Authorization: Basic"&& pOptions["authval"] & cr before couchHeaders
      break
    case "cookie"
      put "Cookie: AuthSession="& pOptions["authval"] &cr before couchHeaders
      break
    default
    case "login"
      put "Authorization: Basic"&& base64encode(pOptions["authval"]) & cr before couchHeaders
      break
  end switch
  set the httpheaders to couchHeaders
end couch.setHeaders

private function couch.DBURL pURL pDB pParams pFunk pDocID
  if pDB is not empty then put urlencode(pDB) into pDB
  if pDocID is not empty and char 1 of pDocID is not "_" then put urlencode(pDocID) into pDocID
  if char 1 to 4 of pURL is not "http" then put "http://" before pURL
  if char -1 of pURL is slash then put empty into char -1 of pURL
  
  if pDB is not empty then put  slash & pDB after pURL
  if pFunk is not empty then put slash & pFunk after pURL
  if pDocID is not empty then  put slash & pDocID after pURL
  
  if char -1 of pURL is slash then put empty into char -1 of pURL
  if pParams is not empty then put couch.parseParams(pParams) after pURL
  return pURL
end couch.DBURL

	
private function couch.parseParams pParamArray
  -----
  local tParamString
  -----
  if tParamArray is empty then return empty
  put "?" into tParamString
  repeat for each key x in pParamArray
    put x & "=" & pParamArray[x] after tParamString
    put "&" after tParamString
  end repeat
  return char 1 to -2 of tParamString
end couch.parseParams
	
private function couch.returnFormat pResult pFormat
  -----
  local tForm
  -----
  if pFormat is empty then 
    put the preferredFormat of this stack into tForm
    if tForm is empty then
      put "array" into pFormat
    else
      put tForm into pFormat
    end if
  end if
  
  switch pFormat
    case "array"
      return j2a(pResult)
      break
    case "rawjson"
    case "json"
      return pResult
      break
    case "prettyjson"
      return gingerJson(pResult)
      break
  end switch
end couch.returnFormat

function couch.getrev pURL pDB pDocID pOptions
  -----
  local tOptions,tArray
  -----
  
  put pOptions["authtype"] into tOptions["authtype"]
  put pOptions["authval"] into tOptions["authval"]
  put "array" into tOptions["format"]
  put couch.get("doc",pURL,pDB,pDocID,tOptions) into tArray
  return tArray["_rev"]
end couch.getrev

on ___Misc_Functions___
end ___Misc_Functions___

function j2a pJson asUnicode pSkipValidation
  -----
  local tEmpty,tArray
  -----
  
  put "{"&quote&1&quote&":null}" into tEmpty
  replace "[]" with tEmpty in pJson
  switch jsonLibName
    case "fastJSON"
      return fast.jsonToArray(pJson, asUnicode, pSkipValidation) into tArray
      break
    case "easyJSON"
      return arrayFromJson(pJson) into tArray
      break
    case "mergJSON"
    default
      return jsonToArray(pJson) into tArray
      break
  end switch
end j2a

function a2j pArray keepNumeric makePretty
  -----
  local tJson
  -----
  
  switch jsonLibName
    case "fastJSON"
      put fast.arrayToJson(pArray,keepNumeric) into tJson
      break
    case "easyJSON"
      put jsonFromArray(pArray) into tJson
      break
    case "mergJSON"
    default
      put arrayToJson(pArray) into tJson
      break
  end switch
  replace "[null]" with "[]" in tJson
  if makePretty then return gingerJson(tJson)
  return tJson
end a2j

function jsonArrayMaker pArray
  local tKey, tCnt, newArray
  put 0 into tCnt
  repeat for each key tKey in pArray
    add 1 to tCnt
    put pArray[tKey] into newArray[tCnt]
  end repeat
  return newArray
end jsonArrayMaker

private function czVal pValue pDefault
   if pValue is empty or pValue is "default" then
      return pDefault
   else
      return pValue
   end if
end czVal

private function c2a pList
  split pList by comma
  if pList is empty then put empty into pList[1]
  return pList
end c2a

private function delFromlist pList pArray
  -----
  local tDList,tDNewList
  -----
  
  if pList is empty then return pArray
  put array2list(pArray) into tDList
  replace comma with cr in pList
  repeat for each item tName in tDList
    if tName is not among the lines of pList then put tName & comma after tDNewList
  end repeat
  put empty into the last char of tDNewList
  split tDNewList by comma
  return tDNewList
end delFromlist

private function add2list pList pArray
  -----
  local tAList
  -----
  if pList is empty then return pArray
  put array2list(pArray) into tAList
  set itemdel to comma
  repeat for each item tName in pList
    if tName is not among the lines of tAList then put cr & tName after tAList
  end repeat
  split tAList by cr
  return tAList
end add2list

private function array2list pArray
  -----
  local tCnt,tList
  -----
  put the number of lines in the keys of pArray into tCnt
  repeat with x=1 to tCnt
    put pArray[x] after tList
    if x<tCnt then put cr after tList
  end repeat
  return tList
end array2list

private function contentTypeCheck pFileName pType
  -----
  local tFileExt
  -----
  
  set itemdel to "."
  put item -1 of pFileName into tFileExt
  switch tFileExt
    case "ai"
    case "eps"
    case "ps"
      return "application/postscript"
      break
    case "aif"
    case "aiff"
      return "audio/aiff"
      break
    case "asp"
      return "text/asp"
      break
    case "avi"
      return "video/avi"
      break
    case "bmp"
      return "image/bmp"
      break
    case "class"
      return "application/java"
      break
    case "css"
      return "text/css"
      break
    case "doc"
    case "word"
      return "application/msword"
      break
    case "exe"
      return "application/octet-stream"
      break
    case "gif"
      return "image/gif"
      break
    case "htm"
    case "html"
    case "htx"
    case "shtml"
      return "text/html"
      break
    case "ico"
      return "image/x.icon"
      break
    case "jpeg"
    case "jpg"
      return "image/jpeg"
      break
    case "js"
      return "application/javascript"
      break
    case "log"
    case "lst"
    case "text"
    case "txt"
      return "text/plain"
      break
    case "m2a"
    case "m2v"
    case "mpa"
    case "mpeg"
    case "mpg"
      return "video/mpeg"
      break
    case "mid"
    case "midi"
      return "audio/midi"
      break
    case "moov"
    case "mov"
    case "qt"
      return "video/quicktime"
      break
    case "mp3"
      return "audio/mpeg3"
      break
    case "pdf"
      return "application/pdf"
      break
    case "pic"
    case "pict"
      return "image/pict"
      break
    case "png"
      return "image/png"
      break
    case "ppt"
      return "application/powerpoint"
      break
    case "rtf"
      return "text/richtext"
      break
    case "svg"
      return "image/svg+xml"
      break
    case "tif"
    case "tiff"
      return "image/tiff"
      break
    case "ttf"
      return "application/x-font-ttf"
      break
    case "woff"
      return "application/x-font-woff"
      break
    case "xls"
      return "application/excel"
      break
    case "xml"
      return "text/xml"
      break
    case "zip"
      return "application/zip"
      break
    default
      switch pType
        case "text"
        case "ascii"
          return "text/plain"
          break
        default
          return "application/octet-stream"
          break
      end switch
      break
  end switch
end contentTypeCheck

on ___Prettify_JSON___
end ___Prettify_JSON___

function gingerJson pJson
  -----
  local tEscape,tColon,tJArray
  local tLevel,tMaxLevel,tComma
  local tValue,tPretty
  -----
  
  put 0 into tLevel
  put 0 into tMaxLevel
  put false into tComma
  put false into tEscape
  put false into tColon
  put false into tJArray
  put false into tValue
  put empty into tPretty
  repeat for each char tChar in pJson
    switch tChar
      case "{"
        if tEscape is false then
          if (tComma is true and tColon is false) or \
                (tJArray is true and tColon is false)  then 
            put tabCount(tLevel) after tPretty
            put false into tComma
          end if
          put "{" & cr after tPretty
          add 1 to tLevel
          put tabCount(tLevel) after tPretty
        else
          put "{" after tPretty
          put false into tEscape
        end if
        break
      case "}"
        if tEscape is false then
          subtract 1 from tLevel
          put cr & tabCount(tLevel) & "}" after tPretty
        else
          put "}" after tPretty
          put false into tEscape
        end if
        break	
      case "["
        if tEscape is false then
          if tComma is true and tColon is false then 
            put tabCount(tLevel) after tPretty
            put false into tComma
          end if
          put "[" & cr after tPretty
          add 1 to tLevel
          put true into tJArray
          put tabCount(tLevel) after tPretty
        else
          put "[" after tPretty
          put false into tEscape
        end if
        break
      case "]"
        if tEscape is false then
          subtract 1 from tLevel
          put cr & tabCount(tLevel) & "]" after tPretty
        else
          put "]" after tPretty
          put false into tEscape
        end if
        break	
      case colon
        if tEscape is false then put true into tColon
        put colon after tPretty
        break
      case slash
        if tEscape is true then put false into tEscape else put true into tEscape
        put slash after tPretty
        break
      case quote
        if tEscape is true then 
          put false into tEscape
        else if tValue is false then
          put true into tValue
        else
          put false into tValue
        end if
        put quote after tPretty
        break
      case comma
        if tValue is false then
          put comma & cr & tabCount(tLevel) after tPretty
          put true into tComma
        else
          put comma after tPretty
          --put false into tEscape
        end if
        break	
      default
        put tChar after tPretty
        put false into tColon
    end switch		
    if tLevel > tMaxLevel then put tLevel into tMaxLevel
  end repeat
  	   
  repeat with x=1 to tMaxLevel
    replace cr&tabCount(x)&cr with cr in tPretty
  end repeat
  return tPretty
end gingerJson
		 
private function tabCount pCount
  -----
  local tReturn
  -----
  
  repeat with x = 1 to pCount
    put tab after tReturn
  end repeat
  return tReturn
end tabCount
	
function snapJson pJson
  replace tab with empty in pJson
  replace cr with empty in pJson
  return pJson
end snapJson

private function enQ pItem
  return quote & pItem & quote
end enQ

on __FASTJSON___
end __FASTJSON___

##
# -------------------------------------------------------------------
# FASTJSON v1.1.2
# -------------------------------------------------------------------
#
# Bob Hall
# May 15, 2016
#
# By combining the best of easyjson and libjson and adding in
# performance enhancements, fastjson improves the speed of encoding
# and decoding Livecode arrays to/from JSON.
#
# Credit goes first to Mark Smith for creating the original libjson
# library and to Igor de Oliveira Couto who created the also excellent
# easyJson library.
#
# I am combining routines from both of these libraries to give us
# a decent boost in performance for JSON to/from Array needs.
# Yes, you can go faster than this with an custom coded extension.
# But I find the speed of this library to be pretty impressive.
#
# -------------------------------------------------------------------
# Instructions
# -------------------------------------------------------------------
#
# There are 3 calls that you will make from your Livecode scripts.
#
#     fast.arrayToJson(pArrayData, [keepNumeric])
#     fast.jsonToArray(pJsonData, [asUnicode], [skipValidation])
#     isJson(pJsonData)
#
# NOTE:
# You will also find the following for compatibilty with existing
# easyJson scripts
#
#     arrayFromJson(pJsonData) (NOT TESTED)
#     jsonFromArray(pArrayData) (NOT TESTED)
#
# All other functions and commands in this script are for local use
# only.
#
# To use this library in a Stack I would suggest creating a substack
# of your main project named fastJson. Copy and paste the text of
# fastjson.lc minus the first line (<?lc) into the stack script of
# your new substack. In the preOpenStack handler of your main stack:
#
#     start using stack "fastJson"
#
# For livecode server use, include "fastjson.lc" in your server
# script.
#
# -------------------------------------------------------------------
#
##

# DECLARE SCRIPT LOCAL VARIABLES
local sOutputUnicode=""
local sJson=""
local sIndex=0
local sNumTokens=0
local sKeepNumeric=false   --set to keep numeric arrays as json objects instead of arrays
local sFillTheBlanks=false   --set to fill in the blanks between numbers out of order in numeric arrays
local sNull=false    --set to treat the text "null" as the value null 

##
# -------------------------------------------------------------------
#  JSON to Array
# -------------------------------------------------------------------
#
# Convert a valid JSON data structure to a multi-dimensional Livecode
# array.
#
# Prototype:
#
#     put fast.jsonToArray( tJsonData, false, true ) into tArrayData
#
# -------------------------------------------------------------------
#
##
function fast.jsonToArray pJson, asUnicode, pSkipValidation
  local tJson = ""
  local tArray = ""
  
  put asUnicode is true into sOutputUnicode
  put jsonToUtf8(pJson) into tJson
  
  if tJson begins with "fastJson-error" then return tJson
  
  if pSkipValidation then
    tokenize tJson
  else
    if not isJson(tJson) then -- isJson will tokenize tJson for us
      return false
    end if
  end if
  
  //if the result is not empty then return the result
  put 0 into sIndex
  if sJson[1] = "[" then
    add 1 to sIndex
    put jArraytoArray() into tArray
  else
    put jObjectToArray() into tArray
  end if
  
  put empty into sJson
  return tArray
end fast.jsonToArray

##
# -------------------------------------------------------------------
#  Array To JSON
# -------------------------------------------------------------------
#
# Convert a multi-dimensional Livecode array to a valid JSON data
# structure.
#
# Prototype:
#
#     put arrayToJson( tArrayData ) into tJsonData
#
# -------------------------------------------------------------------
#
##
function fast.arrayToJson pArray pkeepNumeric pfillTheBlanks
   local tJSON,  tValue, tKey, tArrayList
   if pkeepNumeric is not empty then put pkeepNumeric into sKeepNumeric
   if pfillTheBlanks is not empty  then put pfillTheBlanks into sFillTheBlanks
   
   if pArray is not an array then return "Parser Error: parameter given is not an array."
   if isNumericalArray(pArray) and keepNumeric is not true and sFillTheBlanks then
      put fillBlanks(pArray) into pArray
   end if
   if isNumericalArray(pArray) and sKeepNumeric is not true then
      # the array's keys are all *numerical*, so the root element will be a JSON *array*
      # if keepNumeric is true, then the keys will remain numeric keys
      put "[" into tJSON
      put the keys of pArray into tArrayList
      sort tArrayList numeric
      repeat for each line tValue in tArrayList
         if tValue is empty then
            put space after tJSON
         else
            put jsonValue(pArray[tValue]) & comma after tJSON
         end if
      end repeat
      put "]" into the last char of tJSON
   else
      # the array's keys are not all numerical, so the root element will be a JSON *object*
     put "{" into tJSON
     put the keys of pArray into tArrayList
     sort tArrayList
      repeat for each line tKey in tArrayList
         # all JSON object keys are double-quoted strings:
         put quote & tKey & quote & ":" & jsonValue(pArray[tKey]) & comma after tJSON
      end repeat
      put "}" into the last char of tJSON
   end if
   return tJSON
end fast.arrayToJson

##
# -------------------------------------------------------------------
#  Validate JSON data structure
# -------------------------------------------------------------------
#
# Prototype:
#
#     if isJson( tJsonData ) then
#        put "Valid JSON" into tTemp
#     else
#        put "ERROR! Not Valid JSON"
#     end if
#
# -------------------------------------------------------------------
#
##

function isJson pJson
     ##local tToken, tDepth
     constant kJSONStart = "{"
     local kJSONEnd = "}"
     local kJSONArrayStart = "["
     local kJSONArrayEnd = "]"
     local kJSONDelimiter = ":"
     local kValidJSONDelimiters = "{}[],:"
     local n
     local tObjectCount = 0 
     local tArrayCount = 0
     
     tokenize pJson

     ##
     ## New code to validate JSON. Catches mis-matched tokens
     ## Adds roughly 10% time to fastJson. Still debating in my head if
     ## this is worth the extra time verses just a basic check...
     ##
     
     put 2 into n
     repeat for each element tToken in sJson
          if (sJson[n-1] is not in kValidJSONDelimiters) and (sJson[n] is not in kValidJSONDelimiters) then
               return false
          end if
          switch tToken
               case kJSONStart
                    add 1 to tObjectCount
                    break
               case kJSONEnd
                    subtract 1 from tObjectCount
                    break
               case kJSONArrayStart
                    add 1 to tArrayCount
                    break
               case kJSONArrayEnd
                    subtract 1 from tArrayCount
                    break
          end switch
          add 1 to n
     end repeat
     if tObjectCount is not 0 then
          put sNumTokens & cr after msg
          return "ERR: unbalanced objects:" && tObjectCount
     end if
     if tArrayCount is not 0 then
          return "ERR: unbalanced arrays:" && tArrayCount
     end if
     
     return true
end isJson


private function jObjectToArray
  local tArray
  local tName
  
  put empty into tArray
  
  -- using a repeat forever with a conditional got small improvement
  repeat forever
    if sIndex > sNumTokens then exit repeat
    add 1 to sIndex
    
    switch sJson[sIndex]
      case "{"
        put jsonDecode(sJson[sIndex + 1]) into tName
        add 1 to sIndex -- we can skip ahead
        break
      case ":"
        if sJson[sIndex + 1] is not "{" then
          put jsonDecode(sJson[sIndex + 1]) into tArray[tName]
        else
          put jObjectToArray() into tArray[tName]
        end if
        break
      case "}"
        return tArray
        break
      case "["
        put jArrayToArray() into tArray[tName]
        break
      case comma -- must be after "[" or will mess up jArrays
        put jsonDecode(sJson[sIndex + 1]) into tName
        add 1 to sIndex -- we can skip ahead
        break
    end switch
    
  end repeat
  return tArray
end jObjectToArray

private function jArrayToArray
  local tKey=0
  local tArray=""
  
  repeat while sIndex <= sNumTokens
    add 1 to sIndex
    
    switch sJson[sIndex]
      case "]"
        return tArray
        break
      case comma
        next repeat
        break
      case "{"
        add 1 to tKey
        subtract 1 from sIndex
        put jObjectToArray() into tArray[tKey]
        break
      case "["
        add 1 to tKey
        put jArrayToArray() into tArray[tKey]
        break
      default
        add 1 to tKey
        put jsonDecode(sJson[sIndex]) into tArray[tKey]
    end switch
  end repeat
end jArrayToArray

private function jsonToUtf8 @pJson
  local tNulls = "1111"
  local tCounter = "1,2,3,4"
  local bigEndian
  
  repeat for each element n in tCounter
    if (byte n of pJson is null) then put 0 into char n of tNulls
  end repeat
  
  put (char 1 of (binaryencode("I",1)) is null) into bigEndian
  
  switch tNulls
    case "1111"  -- UTF-8
      return pJson
      break
    case "0101"  -- UTF-16BE
      if bigEndian then
        return utf8encode(pJson, true)
      else
        return utf8encode(swapEndianness(pJson), true)
      end if
      break
    case "1010"  -- UTF-16LE
      if not bigEndian then
        return utf8encode(pJson, true)
      else
        return utf8encode(swapEndianness(pJson), true)
      end if
      break
    case "0001"  -- UTF-32BE
      return "fastJson-error: 4 byte unicode, can't decode"
      break
    case "1000"  -- UTF-32LE
      return "fastJson-error: 4 byte unicode, can't decode"
      break
  end switch
end jsonToUtf8

private function utf8encode pString, pIsUnicode
  if pIsUnicode then
    return unidecode(pString, "UTF8")
  else
    return unidecode(uniencode(pString),"UTF8")
  end if
end utf8encode

private function utf8decode pString, pToUnicode
  if pToUnicode then
    return uniencode(pString,"UTF8")
  else
    return unidecode(uniencode(pString,"UTF8"))
  end if
end utf8decode

private function jsonDecode pString
  local tCode
  local tChar
  
  switch pString
    case "false"
      return "false"
      break
    case "true"
      return "true"
      break
      #
      # SPECIAL CASE. Need to catch this in JSON or performace takes a hit.
      #
    case ""
      return empty
      break
   case "null"
      if sNull then return "null" else return empty
      break
    default
      if pString is a number then
        return pString
      else
        replace "\" & quote with quote in pString
        replace "\\" with "\" in pString
        replace "\b" with numtochar(8) in pString
        replace "\t" with numtochar(9) in pString
        replace "\f" with numtochar(12) in pString
        replace "\r" with numtochar(13) in pString
        replace "\n" with numtochar(10) in pString
        
        -- some more common unicode escapees
        replace "\u0022" with quote in pString
        replace "\u005C" with "\" in pString
        -- any others
        replace "[NUL]" with numtobyte(0) in pString
        
        ##
        # JSON encoders escape unicode characters as "\uHHHH",
        # where 'H' is a hexadecimal digit. Convert to UTF8
        #
        repeat while matchtext(pString,"\\u([0-9A-Fa-f]{4})",tCode)
          set the useunicode to true
          put unidecode(numtochar(baseconvert(tCode,16,10)),"UTF8") into tChar
          replace ("\u" & tCode) with tChar in pString
        end repeat
        
        if not sOutputUnicode then
          return utf8decode(pString)
        else
          return pString
        end if
      end if
  end switch
end jsonDecode


##
# -------------------------------------------------------------------
#
# This function checks the keys of a LiveCode array,
# and returns TRUE if all the keys are numerical - otherwise, returns false.
#
#  @param pArray a LiveCode array
#  @return TRUE if the array's keys are all numerical, otherwise FALSE
#
# -------------------------------------------------------------------
#
private function isNumericalArray @pArray
   local tKeys, aKey
   put the keys of pArray into tKeys

   repeat for each line aKey in tKeys
      if aKey is not a number then
         -- as soon as we don't get a number, get outa here!
         return false
         exit isNumericalArray
      end if
   end repeat
   return true
end isNumericalArray

##
# -------------------------------------------------------------------
#
# This function takes a LiveCode value, and produces a string representing
# a valid JSON 'value', as per http://www.json.org/.
#  @param pValue any LiveCode value: array, string, number, date, colour, boolean, etc.
#  @return a string representing a valid and comparable JSON 'value' - JSON values are:
#        number, string, boolean, array or object.
#        LiveCode 'empty' returns JSON 'null'.
#
# -------------------------------------------------------------------
#

private function jsonValue pValue
   if sNull and pValue is "null" then put empty into pValue
   switch
      case pValue is an array
         # this allows us to have nested JSON objects and arrays:
         return fast.arrayToJson(pValue)
         break
      case pValue is empty
         return "null"
         break
      case pValue is a boolean
         if pValue then return "true"
         else return "false"
         break
      case pValue is a number
         -- need to catch when a "number" starts with a 0
         -- decided to return this as a quoted string
         -- JSON lint throws an exception if a number starts with a 0
         if (character 1 of pValue = 0) and not (character 2 of pValue = ".") and (length(pValue) > 1) then
            return quote & pValue & quote
         end if
         -- there is an "anomoly" in LC where "inf" and "Infinity" are getting through "is a number"
         -- function. Not sure what the result will be but the code below will catch both.
         -- I have submitted the following bugs: 16160, 16162, 16163
         if char 1 of pValue is "i" then
            return quote & pValue & quote
         else
            return pValue
         end if
      default
         # any other value is processed as a string.
         # JSON strings require that certain characters be 'escaped' with a backslash:
         replace "\" with "\\" in pValue // the backslash itself
         replace quote with ("\" & quote) in pValue // the double quote
         replace "/" with "\/" in pValue // the (forward) slash
         replace tab with "\t" in pValue // the tab
         replace return with "\n" in pValue // the return
         return quote & pValue & quote
   end switch
end jsonValue

private command tokenize @pJson
  local prevToken
  
  put empty into sJson
  put 0 into sNumTokens
  
  # escaped quotes < \" > and reverse-solidus < \\ > will confuse the tokenizer
  # so we replace them with "\u0022" and "\u005C" which we'll unescape
  # with all the other unescapes when we parse - jsonDecode()
  replace "\\" with "\u005C" in pJson
  replace "\" & quote with "\u0022" in pJson
  replace numtobyte(0)  with "[NUL]" in pJson
  
  put 1 into sIndex
  put "" into prevToken
  repeat for each token tToken in pJson
    switch
      case tToken is in "+-"
        # since "+" & "-" are rev tokens, but not jSon tokens,
        # we have to prepend them to the next token
        put tToken after prevToken
        break
      case (prevToken is in "+-") and (tToken is not a number)
        add 1 to sNumTokens
        put prevToken into sJson[sNumTokens]
        put "" into prevToken
        add 1 to sNumTokens
        put tToken into sJson[sNumTokens]
        break
      default
        add 1 to sNumTokens
        put prevToken & tToken into sJson[sNumTokens]
        put "" into prevToken
    end switch
  end repeat
end tokenize

function numTokens @pJson
  tokenize pJson
  
  return sNumTokens
end numTokens

private function fillBlanks pArray
   local tKeyList, tKey, tLast
   put the keys of pArray into tKeyList
   sort tKeyList numeric
   put the last line of tKeyList into tLast
   repeat with tKey=1 to tLast
      if pArray[tKey] is empty then put "null" into pArray[tKey]
   end repeat
   return pArray
end fillBlanks

