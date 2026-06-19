 
 /*------------------------------------------------------------------------
    File        : webhandler
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : khoury
    Created     : Thu Apr 03 17:48:17 CEST 2025
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.* from propath.
using Progress.Lang.*.
using OpenEdge.Web.WebResponseWriter.
using OpenEdge.Net.HTTP.StatusCodeEnum.
using OpenEdge.Web.WebHandler.

block-level on error undo, throw.

class TestHandler inherits WebHandler: 

    method override protected integer HandleNotAllowedMethod( input poRequest as OpenEdge.Web.IWebRequest ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    method override protected integer HandleNotImplemented( input poRequest as OpenEdge.Web.IWebRequest ):
        
        undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

    end method.

    
    
    /*------------------------------------------------------------------------------
            Purpose: Default handler for the HTTP GET method. The request being 
                     serviced and an optional status code is returned. A zero or 
                     null value means this method will deal with all errors.                                                               
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
     method override protected integer HandleGet( input poRequest as OpenEdge.Web.IWebRequest ):
     
    
        define variable oResponse as OpenEdge.Net.HTTP.IHttpResponse no-undo.
        define variable oWriter   as OpenEdge.Web.WebResponseWriter  no-undo.
        define variable jsonResponse as Progress.Json.ObjectModel.JsonObject        no-undo.
        define variable oHeader as OpenEdge.Net.HTTP.HttpHeader.
        define variable cCustName   as char  no-undo.

            DEFINE VARIABLE cToken AS CHARACTER NO-UNDO.
        DEFINE VARIABLE rToken AS RAW       NO-UNDO.
        DEFINE VARIABLE hNewCP AS HANDLE    NO-UNDO.

        //SECURITY-POLICY:REGISTER-DOMAIN("loulou","loulou").
        //SECURITY-POLICY:LOCK-REGISTRATION.

        /* 1. Lire le header X-Client-Principal */
    /*  oHeader = poRequest:GetHeader('X-OE-CLIENT-CONTEXT-ID').
        cToken = oHeader:GetBaseValue().
    
            message " cToken " + cToken.

        IF cToken = '' OR cToken = ? THEN
            RETURN 401. /* Unauthorized */

        /* 2. Reconstruire et importer le CP */
        rToken = BASE64-DECODE(cToken).
        CREATE CLIENT-PRINCIPAL hNewCP.
        hNewCP:IMPORT-PRINCIPAL(rToken).
      //  SESSION:REQUEST-INFO:SETCLIENTPRINCIPAL(hNewCP).
        message "zzhNewCP:DOMAIN-NAME" hNewCP:DOMAIN-NAME.

        /* 3. Vérifier que le CP n'est pas expiré */
        // IF hNewCP:LOGIN-STATE <> "LOGIN" THEN DO:
        //     message "hNewCP:LOGIN-STATE " hNewCP:LOGIN-STATE VIEW-AS ALERT-BOX.
        //     DELETE OBJECT hNewCP.
        //     RETURN 401.
        // END.


        /* 4. Appliquer le CP à la session courante */
        SECURITY-POLICY:SET-CLIENT(hNewCP).
        IF ERROR-STATUS:ERROR THEN message "crote".
        ELSE MESSAGE "OK".

        message "hNewCP:LOGIN-STATE " hNewCP:LOGIN-STATE.
       */
        /* The WebResponse body is a wrapper around an entire HTTP response message.
           It contains a status code and reason; headers; cookies and a message body.
           
           API-level doc for this and related classes can be found at
           https://documentation.progress.com/output/oehttpclient/      */
        assign 
            oResponse            = new OpenEdge.Web.WebResponse()
            oResponse:StatusCode = integer(StatusCodeEnum:OK)
            .
        /* This body object can be a string or something else (JsonObject for instance) */ 
        
        //SET-EFFECTIVE-TENANT ("fifi").
        jsonResponse          = new JsonObject().
        jsonResponse:Add("tenant-name", tenant-name()).
         cCustName = string(tenant-name()) + "" + string(tenant-name()).
      
     
        
        assign 
            oResponse:Entity        = jsonResponse
            /* HTTP messages require a content type */
            oResponse:ContentType   = 'application/json':u
            /* ContentLength is good too */
            .
        
        /* The WebResponseWriter ensures that the status line and
           all headers are writted out before the message body/entity. */
        assign 
            oWriter = new WebResponseWriter(oResponse).
        oWriter:Open().
        
        /* Finish writing the response message */
        oWriter:Close().
        
        /* A response of 0 means that this handler will build the entire response;
           a non-zero value is mapped to a static handler in the webapp's /static/error folder.
           The mappings are maintained in the webapps's WEB-INF/web.xml 
           A predefined set of HTTP status codes is provided in the OpenEdge.Net.HTTP.StatusCodeEnum 
           enumeration */
        return 0.
        
     end method. 
     
     
       
    
end class.