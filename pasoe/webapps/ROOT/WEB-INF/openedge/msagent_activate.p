define variable hCP as handle no-undo.
def var lok as logical no-undo.
def var hReqProc as char no-undo.

/*

/**/
DEFINE VARIABLE rCP AS RAW NO-UNDO.
CREATE CLIENT-PRINCIPAL hCP.
/* Lookup client-principal object in context database */
FIND CPObject
WHERE SessionID = SESSION:SERVER-CONNECTION-ID NO-ERROR.
rCP = CPObject.ContextObject.
/* Import client-princpal object, validate, and set user identity */
hCP:IMPORT-PRINCIPAL(rCP).
IF SECURITY-POLICY:SET-CLIENT(hCP) THEN /* Identity is valid */
MESSAGE "valid".
ELSE /* Identity is not valid */
message "invalid".

*/

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


