define input param p_hCP            as handle no-undo. 
define input param p_cCtx           as character no-undo. 

OUTPUT to dumpCP.out.

if (? = p_cCtx) then p_cCtx = "".

if ( NOT valid-handle(p_hCP) ) then
    message p_cCtx "Client-Principal: <invalid-handle>".
else do:
    define variable cList           as character no-undo. 
    define variable iListSize       as integer initial 0 no-undo. 
    define variable iListPos        as integer no-undo. 


    message p_cCtx "Client-Principal:".
      if ( p_hCP:qualified-user-id = "") OR ( p_hCP:qualified-user-id = ?) then
          message "    ID:         '" + p_hCP:qualified-user-id + "'".
    message "    qualified-user-id:" p_hCP:qualified-user-id.
    message "    domain:"     p_hCP:domain-name.
    message "    session-id:" p_hCP:session-id.
    message "    state:     " p_hCP:login-state.
    message "    created:   " p_hCP:seal-timestamp. 

    if (? <> p_hCP:login-expiration-timestamp ) then
        message "       expires:" string(p_hCP:login-expiration-timestamp).  
    if ("" <> p_hCP:state-detail ) then
        message "       details:" p_hCP:state-detail.
    if ("" <> p_hCP:roles ) then
        message "         roles:" p_hCP:roles.
    if ("" <> p_hCP:domain-description ) then
        message "   domain desc:" p_hCP:domain-description.
    if ("" <> p_hCP:domain-type ) then
        message "  domain type:" p_hCP:domain-type.
    if ("" <> p_hCP:login-host ) then
        message "    login host:" p_hCP:login-host.
    if ("" <> p_hCP:audit-event-context ) then
        message "     audit ctx:" p_hCP:audit-event-context.
    if ("" <> p_hCP:client-tty ) then
        message "    client tty:" p_hCP:client-tty.
    if ("" <> p_hCP:client-workstation ) then
        message "    client wrk:" p_hCP:client-workstation.

    cList = p_hCP:list-property-names.
    iListSize = num-entries(cList, ",").
    if ( 0 < iListSize ) then do iListPos = 1 to iListSize:
        define variable cProp       as character no-undo. 
        define variable cVal        as character no-undo. 

        message "    properties:".
        cProp = entry(iListPos, cList, ",").
        cVal = p_hCP:get-property(cProp).
        if (cProp NE 'jti') then
        message "          property:" cProp ", value:" cVal.
    end.
message "p_hCP:db-list: " p_hCP:db-list.
    cList = p_hCP:db-list.
    iListSize = num-entries(cList, ",").
    if ( 0 < iListSize ) then do iListPos = 1 to iListSize:
        define variable cLDB        as character no-undo. 
        define variable cTenant     as character no-undo. 
        define variable cTenantID   as integer no-undo. 

        message "    tenant db list:".
        cLDB = entry(iListPos, cList, ",").
        cTenant = p_hCP:tenant-name(?).
        cTenantID = p_hCP:tenant-id(?).
        /*  cTenant = p_hCP:tenant-name(cLDB).
        cTenantID = p_hCP:tenant-id(cLDB). */
        message "          db:" cLDB ", tenant:" cTenant ", tenant-id:" string(cTenantID).
    end. 
end.

OUTPUT CLOSE.

