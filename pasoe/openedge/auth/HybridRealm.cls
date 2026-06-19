  /*------------------------------------------------------------------------
    File        : HybridRealm
    Purpose     : REST Hybrid Realm for Single Point of Authentication
    Syntax      : 
    Description : Singleton class that implements IHybridRealm for use as
                  a single point of authentication for REST.
    Author(s)   : davec,knavneet,dlampe
    Created     : Tue Feb 26 10:41:36 EST 2013
    Notes       : 
  ----------------------------------------------------------------------*/



using Progress.Lang.*.

using Progress.Security.Realm.IHybridRealm.

using auth.*.



routine-level on error undo, throw.



class auth.HybridRealm implements IHybridRealm:
    define private static variable attributes as character no-undo initial "lastname,firstname,phone,email,description". 
    define private /*STATIC*/ variable debugMsg as logical no-undo initial false.
    define private /*STATIC*/ variable passwd as character no-undo.
    define private variable role as character no-undo.
    define private variable spaProps as class auth.Properties.



    constructor public HybridRealm (  ):
        super ().
MESSAGE "?"
VIEW-AS ALERT-BOX.
        spaProps = new Properties("spaservice.properties").
        passwd = spaProps:GetCharacterProperty("Password", "").
        role = spaProps:GetCharacterProperty("Role", "").
        debugMsg = spaProps:GetLogicalProperty("DebugMsg", ?).

        if debugMsg then do:
            message "Loaded property file spaservice.properties".
            message "   Password: "  passwd.
            message "   Role: " role.
            message "   DebugMsg: " debugMsg.
        end. 
    end constructor.



    method public character GetAttribute( input userNum as integer, input attrName as character ):
        define variable retVal   as character no-undo.
        define variable theUserId as character no-undo. /* fully qualified user name */
        find first _User where _User._User_number = userNum no-error.
        if available _User then 
        do:
            if ( _User._Domain-Name = "" ) then
                theUserId = _User._Userid.
            else
                theUserId = _User._Userid + "@" + _User._Domain-Name.
            case caps(attrName):
                /* REST/RB required attrNames- BEGIN */
                when "ATTR_EXPIRED" then 
                    do:
                        if ( _User._Account_expires < now ) then
                            retVal = "1". /* Expired */
                        else
                            retVal = "0". /* !Expired */
                    end.
                when "ATTR_ENABLED" then 
                    do:
                        if ( ? = _User._Disabled or _User._Disabled = no ) then
                            retVal = "1". /* Enabled */
                        else
                            retVal = "0". /* !Enabled */
                    end.
                when "ATTR_ROLES" then 
                    do:
                        define variable roles as character no-undo.
                        define variable count as integer   initial 0 no-undo.
                        roles = ?.
                        for each _sec-granted-role where _sec-granted-role._grantee = theUserId :
                            message "Found role '" + _sec-granted-role._role-name + "' for userid" + "(" theUserId ")".
                            if ( count = 0 ) then
                                roles = "".
                            else
                                roles = roles + ",".
                            roles = roles + _sec-granted-role._Role-name.
                            count = count + 1.
                        end.
                        message "Found '" roles "' roles for user-id" + "(" theUserId ")".
                        retVal = roles.
                    /* REST/RB required attrNames END */
                    end.
                otherwise 
                do:
                    message "Unknown attribute name in GetAttribute:" attrName.
                    retVal = ?.
                end.
            end.
        end.
        else 
        do:
            undo, throw new Progress.Lang.AppError("Invalid User Id", 1).
        end.
        release _User.
        return retVal.
    end method.
    


    method public character extent GetAttributeNames( input theUserId as integer ):
        define variable results as character extent no-undo.
        define variable attrNames as character extent 10 no-undo.
        define variable attrVal as character no-undo.
        define variable numAttrs as integer no-undo initial 0.
        define variable i as integer no-undo.

        if this-object:ValidateClient() = false then
            undo, throw new Progress.Lang.AppError("Unauthorized client", 1).

        if debugMsg then 
            message "Getting attributes for user number " theUserId.

        find first _User where _User._User_number = theUserId no-error.
        if available _User then do:
            /* Check to see what attributes have values */
            attrVal = _User._Surname.

            if attrVal <> ? then do:
                 numAttrs = numAttrs + 1.
                 attrNames[numAttrs] = "lastname".
            end.

            attrVal = _User._Given_name.

            if attrVal <> ? then do:
                numAttrs = numAttrs + 1.
                 attrNames[numAttrs] = "firstname".
            end.

            attrVal = _User._Telephone.

            if attrVal <> ? then do:
                numAttrs = numAttrs + 1.
                 attrNames[numAttrs] = "phone".
            end.

            attrVal = _User._Email.

            if attrVal <> ? then do:
                numAttrs = numAttrs + 1.
                 attrNames[numAttrs] = "email".
            end.

            attrVal = _User._Description.

            if attrVal <> ? then do:
                numAttrs = numAttrs + 1.
                 attrNames[numAttrs] = "description".
            end.

            attrVal = _User._Userid.

            if attrVal <> ? then do:
               numAttrs = numAttrs + 1.
               attrNames[numAttrs] = "userid".
            end.

            if numAttrs > 0 then do:
                if debugMsg then 
                    message "Number of attribute names: " numAttrs.
                extent(results) = numAttrs.
                do i = 1 to numAttrs:
                    results[i] = attrNames[i].
                    if debugMsg then 
                        message results[i].
                end.
            end.
        end.
        else   
            undo, throw new Progress.Lang.AppError("User not found").

        release _User.
        return results.
    end method.



    method public character extent GetUserNames(  ):
        define variable results as character extent no-undo.
        define variable num as integer no-undo initial 0.

        if this-object:ValidateClient() = false then
            undo, throw new Progress.Lang.AppError("Unauthorized client", 1).

        /* First count the names */
        for each _User:
            num = num + 1.
        end. 

        extent(results) = num.
        num = 1.

        for each _User:
            results[num] = _User._Userid.
            num = num + 1.
        end.

        release _User.
        return results.
    end method.



    method public character extent GetUserNamesByQuery( input queryString as character ):
        define variable results as character extent no-undo.
        define variable num as integer no-undo initial 0.

        if this-object:ValidateClient() = false then
            undo, throw new Progress.Lang.AppError("Unauthorized client", 1).

        if debugMsg then 
            message "QueryString = " queryString. 

        /* First count the names */
        for each _User where _User._Userid matches queryString:
            if debugMsg then 
                message "Match: " _User._Userid.
            num = num + 1.
        end. 

        if num = 0 then do:
            if debugMsg then 
                message "No users found".
            return results.
        end.

        extent(results) = num.
        num = 0.

        for each _User where _User._Userid matches queryString:
            num = num + 1.
            results[num] = _User._Userid.
        end.

        if debugMsg then 
            message "Found " num " users".

        release _User.
        return results.
    end method.



    method public character extent GetUserNamesByQuery( input attrName as character, input attrValue as character ):
        define variable results as character extent no-undo.
        define variable temp as character extent 100 no-undo.
        define variable num as integer no-undo initial 0.
        define variable whichAttr as integer no-undo.

        if this-object:ValidateClient() = false then
            undo, throw new Progress.Lang.AppError("Unauthorized client", 1).

        if debugMsg then 
            message "Attribute name: " attrName " Attribute value: " attrValue.

        whichAttr =  lookup(attrName, attributes).
        if whichAttr = 0 then return results.

        /* First count the names */
        for each _User:
            case whichAttr:
                when 1 then
                    if _User._Surname matches attrValue then do:
                        if debugMsg then 
                            message "Match: " _User._Userid.

                        num = num + 1.
                        temp[num] = _User._Userid.
                    end.

                when 2 then 
                    if _User._Given_name matches attrValue then do:
                        if debugMsg then 
                            message "Match: " _User._Userid.

                        num = num + 1.
                        temp[num] = _User._Userid.
                    end.

                when 3 then 
                    if _User._Telephone matches attrValue then do:
                        if debugMsg then 
                            message "Match: " _User._Userid.

                        num = num + 1.
                        temp[num] = _User._Userid.
                    end.

                when 4 then 
                    if _User._Email matches attrValue then do:
                        if debugMsg then 
                            message "Match: " _User._Userid.

                        num = num + 1.
                        temp[num] = _User._Userid.

                    end.

                when 5 then 
                    if _User._Description matches attrValue then do:
                        if debugMsg then 
                            message "Match: " _User._Userid.

                        num = num + 1.
                        temp[num] = _User._Userid.
                    end.
            end.
        end. 

        

        if num = 0 then do:
            if debugMsg then 
                message "No users found".

            return results.
        end.

        

        extent(results) = num.
        do whichAttr = 1 to num:
            results[whichAttr] = temp[whichAttr].
        end.

        if debugMsg then 
            message "Found " num " users".

        release _User.
        return results.
    end method.




    method public logical RemoveAttribute( input theUserId as integer, input attrName as character ):
        define variable retVal as logical no-undo initial true.

        if this-object:ValidateClient() = false then
            undo, throw new Progress.Lang.AppError("Unauthorized client", 1).

        if debugMsg then 
            message "Attempting to remove Attribute " attrName " for user number " theUserId.

        find first _User where _User._User_number = theUserId no-error.
        if available _User then do:
            case attrName:
                when "lastname" then
                    _User._Surname = ?.

                when "firstname" then 
                    _User._Given_name = ?.

                when "phone" then 
                    _User._Telephone = ?.

                when "email" then 
                    _User._Email = ?.

                when "description" then 
                    _User._Description = ?.

                otherwise do:
                    retVal = false.
                    release _User.
                end.
            end.
        end.
        else   
            undo, throw new Progress.Lang.AppError("Invalid User Id").

        release _User.
        return retVal.
    end method.



    method public logical SetAttribute( input theUserId as integer, input attrName as character, input attrValue as character ):
        define variable retVal as logical no-undo initial true.

        if this-object:ValidateClient() = false then
            undo, throw new Progress.Lang.AppError("Unauthorized client", 1).

        if debugMsg then 
            message "Attempting to set Attribute " attrName " for user number " theUserId " with a value of " attrValue.

        find first _User where _User._User_number = theUserId no-error.
        if available _User then do:
            case attrName:
                when "lastname" then
                    _User._Surname = attrValue.

                when "firstname" then 
                    _User._Given_name = attrValue.

                when "phone" then 
                    _User._Telephone = attrValue.

                when "email" then 
                    _User._Email = attrValue.

                when "description" then 
                    _User._Description = attrValue.

                otherwise do:
                    retVal = false.
                    release _User.
                end.
            end.
        end.
        else   
            undo, throw new Progress.Lang.AppError("Invalid User Id").

        release _User.
        return retVal.
    end method.


    method protected logical ValidateClient(  ):
        define variable result as logical no-undo initial false.
        define variable hCP as handle no-undo.

        hCP = session:current-request-info:GetClientPrincipal().
message "passwd "  passwd
view-as alert-box.
        if (? <> hCP) then
            result = hCP:validate-seal (passwd).

        if RESULT = true then do:
            if hCP:roles <> role then 
                RESULT = false.
        end.    

        return result.
    end method.



    method public logical ValidatePassword( input theUserId as integer, input password as character ):     
        define variable retVal as logical no-undo initial false.      

        if this-object:ValidateClient() = false then
            undo, throw new Progress.Lang.AppError("Unauthorized client", 1).

        if debugMsg then do:
            message "Validate password using basic".
            message "Password: " password.
        end.

        find first _User where _User._User_number = theUserId no-error.
        if available _User then do:
            if _User._Password = ENCODE(password) then 
                retVal = true.
            else
                return false.
        end.
        else   
            undo, throw new Progress.Lang.AppError("Invalid User Id").

        release _User.
        return retVal.
    end method.



    method public logical ValidatePassword( input theUserId as integer, input digest as character, input nonce as character, input timestamp as character ):
        define variable retVal as logical no-undo initial false.
        define variable password as character no-undo.
        define variable myDigest as character no-undo.
        define variable df as character no-undo. 
        define variable remoteTS as datetime-tz no-undo.
        define variable dif as int64 no-undo.
        define variable hash as raw no-undo.

        if this-object:ValidateClient() = false then
            undo, throw new Progress.Lang.AppError("Unauthorized client", 1).

        find first _User where _User._User_number = theUserId no-error.
        if available _User then do:
            password = _User._Password.
        end.
        else 
          undo, throw new Progress.Lang.AppError("User not found").

        release _User.

        if debugMsg then do: 
            message "Validate password using digest".
            message "Digest: " digest.
            message "Nonce: " nonce.
            message "Timestamp: " timestamp.
        end.

        df = session:date-format.
        session:date-format = "ymd".
        remoteTS = datetime-tz(timestamp).
        session:date-format = df.

        dif = absolute(interval(now, remoteTS, "seconds")).

        if dif > 1 then
          undo, throw new Progress.Lang.AppError("Old timestamp sent").

        myDigest = password + nonce + timestamp.
        hash = sha1-digest(myDigest).
        myDigest = base64-encode(hash).

        if debugMsg then 
            message "Computed digest: " myDigest.

        if myDigest = digest then 
            retVal = true.
        else
            retVal = false.

        return retVal.
    end method.



    method public integer ValidateUser( input userName as character ):
        define variable userNum as integer no-undo initial -1.
        define variable userDomain as character no-undo.
        
        if debugMsg then 
            message "userName: " userName.

        if this-object:ValidateClient() = false then
            undo, throw new Progress.Lang.AppError("Unauthorized client", 1).
            
        if index(userName, "@") > 0 then do:
            userDomain = entry(2, userName, "@").
            userName = entry(1, userName, "@").
        end.            

        find first _User where _User._Userid = userName and _User._Domain-Name = userDomain no-error.

        if available _User then do:
            userNum = _User._User_number.
            
            if debugMsg then 
                message "userNum: " userNum.

            release _User.

        end.
        else 
            message "userName " userName " not found!".

        return userNum.
    end method.

end class.