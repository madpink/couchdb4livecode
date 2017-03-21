/*	  <?lc
Daybed - A Library for Apache CouchDB  version: 0.9.142   April 10, 2016

contact:   pink@mad.pink (aka Greg Miller)
	
This is a simple library that calls CouchDB's REST functions.
	
---FUNCTION PARAMETERS---

pFunk - (always required) Couch function being called, without the leading underscore, for example "all_docs"

pURL - (always required) the URL of the CouchDB installation, including "http://", the port numer and a trailing slash
For example:   "http://192.168.23.42:5984/"
With username/password:    "http://admin:trustno1@192.168.23.42:5984/"

pDB - (required when acting on or retrieving from a database) - the name of the database being accessed

pDocID - (required for most get functions) the document "_id" being retrieved
for design documents, use the pDocID param to specify it
for selecting a view from a design document, add a slash with the view name to pDocID, for example:
for the following view call /_design/querymon/_view/phone
put querymon/phone into pDocID
			
pDoc - (required for most put and post functions) array containing the data being converted into a document for the database

pParams - an array with any OPTIONAL parameters, with the parameter as a key.
For example:  to download documents when running the _all_docs function, and limit the list to only 10 records:
put true into tParams["include_docs"]
put 10 into tParams["limit"]

pOptions - (optional) header options, including user and pass (see "Authentication"), also used in "config" operations
also can include pOptions["format"] with "array", "rawjson" or "prettyjson" for the return format
the stack can have a customProperty called "preferredFormat" which can be one of those three values,
if pOptions["format"] is blank, then "preferredFormat" will be used, if it is not set, then "array" will be used

couch.adduser is for creating a new user in the "_users" database

if you have "couchperuser" installed (https://github.com/etrepum/couchperuser) then use the 
couch.peruserDB function to find the database name assoc

NOTE: a library for decoding and encoding JSON needs to be added, I recommend one of these:
https://github.com/bhall2001/fastjson
https://github.com/luxlogica/easyjson

TO-DO 
--offline syncable database
--need to upload DayBed Toolbox
*/


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
          case "design"
          case "ddoc"
               put couch.ddoc(pDocID,pOptions) into pDocID
               put empty into pFunk
               break
          case "config"
               put "_" before pFunk
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
               put "_" before pFunk
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
          case "design"
          case "ddoc"
               put pDoc["_id"] into pDocID
               put couch.ddoc(pDocID,pOptions) into pDocID
               put empty into pFunk
               break
          case "config"
               put "_" before pFunk
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
               put "_" before pFunk
               break
     end switch
     
     if pOptions["attachments"] is not empty then 
          put couch.attachments(pOptions["attachments"]) into pDoc["_attachments"]
     end if
     
     couch.setHeaders pOptions
     put couch.DBURL(pURL,pDB,pParams,pFunk,pDocID) into tURL
     
     switch tFunktion
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
          case "design"
          case "ddoc"
               put pDoc["_id"] into pDocID
               put couch.ddoc(pDocID,pOptions) into pDocID
               put empty into pFunk
               break
          default
               put "_" before pFunk
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
               put "_" before pFunk
               break
     end switch
     couch.setHeaders
     put couch.DBURL(pURL,pDB,pParams,pFunk,pDocID) into tURL
     delete URL(tURL)
     put the urlResponse into tResult
     return couch.returnFormat(tResult,pOptions["format"])
end couch.delete

function couch.adduser pURL pUser pPass pOptions pAddDB
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
     put couch.put("users",pURL,,tUser,,pOptions) into tResult
     if pAddDB then
          put couch.userDB(pUser) into tDB
          put couch.put("db",pURL,tDB,,,pOptions) into tNewDB
          put couch.securedb("set",pURL,tDB,pOptions,pUser,,pUser) into tSecure
          put "["&tResult&comma&tNewDB&comma&tResult&"]" into tResult
     end if
     return couch.returnFormat(tResult,tReturnFormat)
end couch.adduser

function couch.securedb pFunk pURL pDB pOptions pAdminNames pAdminRoles pMemberNames pMemberRoles
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

function couch.getrev pURL pDB pDocID pOptions
     put pOptions["authtype"] into tOptions["authtype"]
     put pOptions["authval"] into tOptions["authval"]
     put "array" into tOptions["format"]
     put couch.get("doc",pURL,pDB,pDocID,tOptions) into tArray
     return tArray["_rev"]
end couch.getrev

on ___CouchDB_Experimental_Functions___
end ___CouchDB_Experimental_Functions___

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
     
     if pCouch["load"] is not empty then put dbdb.useDefaults(pCouch) into pCouch
     
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

function couch.userDB pUsername
     -----
     local tDBName, tUser
     -----
     put "user_" into tDBName
     put urlencode(pUsername) into tUser
     replace "%40" with "(at)" in tUser
     replace "%" with "$" in tUser
     replace "." with "(dot)" in tUser
     put tUser after tDBName
     return tDBName
end couch.userDB

function couch.peruserDB pUsername
     -----
     local tDBName, temp
     -----
     ---requires "couchperuser" daemon to be installed
     put binaryDecode("H*",pUsername,tDBName) into temp
     put "user_" before tDBName
     return tDBName
end couch.peruserDB

on ___DaybedDB_SettingsFile_Functions___
end ___DaybedDB_SettingsFile_Functions___

function dbdb.loadSettings
     if "daybedSettings" is not among the lines of the mainStacks then
          put getPath() & "/" & "daybedSettings.dbdb" into tFileName
          if there is no file tFileName then 
               dbdb.settingsFile
          else
               open invisible stack tFileName
          end if
     end if
     put the couchSettings of stack "daybedSettings" into tCouch
     return tCouch
end dbdb.loadSettings

command dbdb.saveSettings pSaveMe pOverwrite
     put dbdb.loadSettings() into tCouchSet
     put getPath() & "/" & "daybedSettings.dbdb" into tFileName
     
     if pOverwrite is true then
          put pSaveMe into tCouchSet
     else
          repeat for each key tKey in pSaveMe
               put pSaveMe[tKey] into tCouchSet[tKey]
          end repeat
     end if
     set the couchSettings of stack tFileName to tCouchSet
     save stack tFileName
end dbdb.saveSettings

command dbdb.addSetting pKey pURL pAuthType pAuthName pDB
     put dbdb.loadSettings() into tSettings
     put pURL into tSettings[pKey]["url"]
     put pAuthType into tSettings[pKey]["options"]["authtype"]
     put pAuthName into tSettings[pKey]["options"]["authname"]
     put pDB into tSettings[pKey]["db"]
     dbdb.saveSettings tSettings
end dbdb.addSetting

command dbdb.settingsFile
     put getPath() into tPath
     if there is no folder tPath then create folder tPath
     create invisible stack "daybedSettings"
     put "http://localhost:5984" into tCouch["local"]["url"]
     set the couchSettings of stack "daybedSettings" to tCouch
     put tPath & "/" & "daybedSettings.dbdb" into tFile
     save stack "daybedSettings" as tFile
end dbdb.settingsFile

function dbdb.useDefaults pCouch
     put loadCouchSettings() into tCouchSet
     ifEmptyFill pCouch["url"],tCouchSet[pCouch["load"]]["url"]
     ifEmptyFill pCouch["options"]["authname"],tCouchSet[pCouch["load"]]["options"]["authname"]
     ifEmptyFill pCouch["options"]["authtype"],tCouchSet[pCouch["load"]]["options"]["authtype"]
     ifEmptyFill pCouch["db"],tCouchSet[pCouch["load"]]["db"]
     return pCouch
end dbdb.useDefaults

function getPath pMainFolder pSubFolder
     if pMainFolder is empty then
          switch the platform
               case "Win32"
               case  "MacOS"
                    put "support" into pMainFolder
                    ifEmptyFill pSubFolder,"DayBedDB"
                    break
               case "iphone"
               case "android"
                    put "documents" into pMainFolder
                    break
               case "Linux"
               case "HTML5"
                    put "home" into pMainFolder
                    ifEmptyFill pSubFolder,"DayBedDB"
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
     ifNotEmptyAppend pSubFolder,tPathName,"/"
     return tPathName
end getPath



on ___CouchDB_Internal_Functions___
end ___CouchDB_Internal_Functions___

--function useDefaults pCouch
--     put loadCouchSettings() into tCouchSet
--     put ifEmptyFill(pCouch["url"],tCouchSet[pCouch["load"]]["url"]) into pCouch["url"]
--     put ifEmptyFill(pCouch["options"]["authname"],tCouchSet[pCouch["load"]]["options"]["authname"]) into pCouch["options"]["authname"]
--     put ifEmptyFill(pCouch["options"]["authtype"],tCouchSet[pCouch["load"]]["options"]["authtype"]) into pCouch["options"]["authtype"]
--     put ifEmptyFill(pCouch["db"],tCouchSet[pCouch["load"]]["db"]) into pCouch["db"]
--     return pCouch
--end useDefaults

function couch.attachments pAtt
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

function couch.aType pType pPath
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

function couch.ddoc pDocID pOptions
     if pDocID is empty then put pOptions["docid"] into pDocID
     if char 1 to 7 of pDocID is not "_design" then put "_design/" before pDocID
     if pOptions["ddocfunc"] is not empty then put "/_" & pOptions["ddocfunc"] after pDocID
     if pOptions["ddocname"] is not empty then put "/" & pOptions["ddocname"] after pDocID
     if pOptions["ddocxtend"] is not empty then put "/" & pOptions["ddocxtend"] after pDocID
     if pOptions["ddocxtend2"] is not empty then put "/" & pOptions["ddocxtend2"] after pDocID
     if pOptions["attachment"] is not empty then put "/" & pOptions["attachment"] after pDocID
     return pDocID
end couch.ddoc

function couch.cookie pResult
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

function couch.simplearray pKey pDoc
     -----
     local tJson, tCount
     -----
     put the number of lines in the keys of pDoc into tCount
     put "{"&quote&pKey&quote&colon&" [" into tJson
     repeat with x=1 to tCount
          put quote & pDoc[x] & quote after tJson
          if x<tCount then put comma after tJson
     end repeat
     put "]  }" after tJson
     return tJson
end couch.simplearray

command couch.setHeaders pOptions
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
          case "login"
               put "Authorization: Basic"&& base64encode(pOptions["authval"]) & cr before couchHeaders
               break
          case "encoded"
               put "Authorization: Basic"&& pOptions["authval"] & cr before couchHeaders
               break
          case "cookie"
               put "Cookie: AuthSession="& pOptions["authval"] &cr before couchHeaders
               break
     end switch
     set the httpheaders to couchHeaders
end couch.setHeaders

function couch.DBURL pURL pDB pParams pFunk pDocID
     if char 1 to 4 of pURL is not "http" then put "http://" before pURL
     if char -1 of pURL is slash then put empty into char -1 of pURL
     ifNotEmptyAppend pDB,pURL,slash
     ifNotEmptyAppend pFunk,pURL,slash
     ifNotEmptyAppend pDocID,pURL,slash
     if char -1 of pURL is slash then put empty into char -1 of pURL
     if pParams is not empty then put couch.parseParams(pParams) after pURL
     return pURL
end couch.DBURL

	
function couch.parseParams pParamArray
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
	
function couch.returnFormat pResult pFormat
     -----
     local tFormat
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

on ___Misc_Functions___
end ___Misc_Functions___

function j2a pJson asUnicode pSkipValidation
     --if easyJson is being used instead of fastJson then
     ----don't include values for asUnicode or pSkipValidation
     put "{"&quote&1&quote&":null}" into tEmpty
     replace "[]" with tEmpty in pJson
     put jsonToArray(pJson, asUnicode, pSkipValidation) into tArray
end j2a

function a2j pArray keepNumeric
     --if easyJson is being used instead of fastJson then
     ----don't include values for keepNumeric
     put arrayToJson(pArray,keepNumeric) into tJson
     replace "[null]" with "[]" in tJson
     return tJson
end a2j

function c2a pList
     split pList by comma
     if pList is empty then put empty into pList[1]
     return pList
end c2a

function delFromlist pList pArray
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

function add2list pList pArray
     if pList is empty then return pArray
     put array2list(pArray) into tAList
     set itemdel to comma
     repeat for each item tName in pList
          if tName is not among the lines of tAList then put cr & tName after tAList
     end repeat
     split tAList by cr
     return tAList
end add2list

function array2list pArray
     put the number of lines in the keys of pArray into tCnt
     repeat with x=1 to tCnt
          put pArray[x] after tList
          if x<tCnt then put cr after tList
     end repeat
     return tList
end array2list

function keyVal pKey pVal
     -----
     local tReturn
     -----
     put quote & pKey & quote & colon & quote & pVal & quote into tReturn
     return tReturn
end keyVal  

command  ifEmptyFill @pFillMe pValue
     if pFillMe is empty then put pValue into pFillMe
end ifEmptyFill
     
command ifNotEmptyAppend pAppendMe @pAppendTo pDivider
     if pAppendMe is not empty then 
          put pAppendTo & pDivider & pAppendMe into pAppendTo
     end if
end ifNotEmptyAppend

function convertParams pParam
     -----
     local temp
     -----
     put pParam into temp
     if temp is empty then return empty
     split temp by return and tab
     repeat for each key theKey in temp
          if temp[theKey] is empty then delete variable temp[theKey]
     end repeat
     return temp
end convertParams

function contentTypeCheck pFileName pType
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
     put 0 into tLevel
     put 0 into tMaxLevel
     put false into tComma
     put false into tEscape
     put false into tColon
     put false into tJArray
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
               case comma
                    if tEscape is false then
                         put comma & cr & tabCount(tLevel) after tPretty
                         put true into tComma
                    else
                         put comma after tPretty
                         put false into tEscape
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
		 
function tabCount pCount
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
