define input parameter startup-data as character no-undo.

define var m_lOk as logical no-undo.

message "running mstenant_startup".

// Loading domain registry for the session
m_lOK = security-policy:load-domains(1).


// Validate if load-domains() executed successfully

if (not m_lOk) then
 do:
     message "Error loading domains" error-status:get-message(1).
     return error "Error in load-domains():" + error-status:get-message(1).
end.
else do:
    message "domain registries loaded successfully".
 end.
