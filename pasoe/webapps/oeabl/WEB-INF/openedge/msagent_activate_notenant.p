 USING OpenEdge.Web.Http.*.
 USING OpenEdge.Net.HTTP.*.
 using Progress.Json.ObjectModel.* from propath.
 
 DEFINE VARIABLE oClient AS IHttpClient  NO-UNDO.

 message "debut msagent_activate_notenant.p" VIEW-AS ALERT-BOX.

/*define variable hCP as handle no-undo.
def var lok as logical no-undo.
def var hReqProc as char no-undo.
define var m_lOk as logical no-undo.
m_lOK = security-policy:load-domains(1).


// Validate if load-domains() executed successfully

if (not m_lOk) then
 do:
     message "Error loading domains" error-status:get-message(1).
     //return error "Error in load-domains():" + error-status:get-message(1).
end.
else message "ok".

//SECURITY-POLICY:REGISTER-DOMAIN("loulou","loulou").
//SECURITY-POLICY:LOCK-REGISTRATION.
// Get the Client-Principal object
hCP = session:current-request-info:GetClientPrincipal(). // An object reference to a Progress.Lang.OERequestInfo class that provides information about the current client request sent to and executing on an application server session.
// Get the Client Request Procedure
hReqProc = session:current-request-info:procedurename.
// Validate the seal of the Client-Principal passed by the Spring Security
//hCP:domain-name = "fifi". // CP is sealed. Can't be changed
//run dumpCP.p (hCP,session:current-request-info:procedureName).

lok = hCP:validate-seal("loulou").
// If success then set it as database client
//SET-EFFECTIVE-TENANT ("fifi").
if (lok) then
 set-db-client(hCP).
else
 return error "CP Validation failed. Keys mismatch".

run dumpCP.p (hCP,session:current-request-info:procedureName).

DELETE OBJECT hCP.
*/

define variable hCP as handle no-undo.
def var lok as logical no-undo.
def var hReqProc as char no-undo.



// Get the Client-Principal object
hCP = session:current-request-info:GetClientPrincipal(). // An object reference to a Progress.Lang.OERequestInfo class that provides information about the current client request sent to and executing on an application server session.
//SECURITY-POLICY:REGISTER-DOMAIN("fifi","fifi").
//SECURITY-POLICY:LOCK-REGISTRATION.
// Get the Client Request Procedure
hReqProc = session:current-request-info:procedurename.
// Validate the seal of the Client-Principal passed by the Spring Security
//hCP:domain-name = "fifi". // CP is sealed. Can't be changed
run dumpCP.p (hCP,session:current-request-info:procedureName).

lok = hCP:validate-seal().
// If success then set it as database client
//SET-EFFECTIVE-TENANT ("fifi").
if (lok) then
 set-db-client(hCP).
else
 return error "CP Validation failed. Keys mismatch".

run dumpCP.p (hCP,session:current-request-info:procedureName).

message "  SESSION:CURRENT-REQUEST-INFO:ClientContextId " SESSION:CURRENT-REQUEST-INFO:ClientContextId.

DEFINE VAR rCP AS RAW NO-UNDO.
rCP =  hCP:EXPORT-PRINCIPAL().
define buffer bCPObject for CPObject.
DO TRANSACTION:
    
CREATE bCPObject.
ASSIGN bCPObject.SessionID = SESSION:CURRENT-REQUEST-INFO:ClientContextId
        bCPObject.ContextObject = rCP.
END.    

message "fin msagent_activate_notenant.p" VIEW-AS ALERT-BOX.


DEFINE VARIABLE rToken   AS RAW       NO-UNDO.
DEFINE VARIABLE cToken   AS LONGCHAR  NO-UNDO.
DEFINE VARIABLE oReq     AS IHttpRequest NO-UNDO.
DEFINE VARIABLE oResp    AS IHttpResponse NO-UNDO.
define variable oHttpClient as IHttpClient no-undo.




oHttpClient = ClientBuilder:Build():Client.

hCP    = SESSION:CURRENT-REQUEST-INFO:GetClientPrincipal().
rToken = hCP:EXPORT-PRINCIPAL().           /* sérialise en RAW */
cToken = BASE64-ENCODE(rToken).            /* encode pour transport HTTP */
message " cToken" string(cToken).
/* 2. Construire la requête vers PASOE B avec le CP en header */
oReq = RequestBuilder:GET('http://localhost:8092/secondary/web/testhandler')
           :AddHeader('X-OE-CLIENT-CONTEXT-ID', string(cToken))
           :Request.

/* 3. Envoyer */
//oResp = HttpClient:Instance():Execute(oReq).

oResp = oHttpClient:Execute(oReq).

message
oResp:StatusCode skip
oResp:ContentType skip
oResp:ContentLength skip(2)
string(cast(oResp:Entity, JsonObject):GetJsonText())
view-as alert-box
.

DELETE OBJECT hCP.


catch err as Progress.Lang.Error:
    message
    err:GetMessage(1)
    view-as alert-box.
end catch.

/*
 DEFINE VARIABLE oReq    AS IHttpRequest  NO-UNDO.
 DEFINE VARIABLE oResp   AS IHttpResponse NO-UNDO.
 DEFINE VARIABLE cToken  AS CHARACTER     NO-UNDO.
 define variable oHttpClient as IHttpClient no-undo.
 
 DEFINE VARIABLE oCp     AS handle NO-UNDO.
 DEFINE VARIABLE cSealedCp AS CHARACTER     NO-UNDO.
 oHttpClient = ClientBuilder:Build():Client.
 /* Récupérer et sceller le CP courant */
 //oCp = Security-Policy:GetClientPrincipal().
 //cSealedCp = oCp:Seal('loulou').  /* passphrase partagée */
 
 /* L'envoyer en header vers le second PASOE */
 oReq = RequestBuilder
             :Get('http://localhost:8092/secondary/web/webhandler')
             :AddHeader('X-OE-CLIENT-CONTEXT', "hCP")
             :Request.
oResp = oHttpClient:Execute(oReq).
*/
