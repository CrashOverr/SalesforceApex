/**************************************************************************************************************
* @desarrollado por Vass
* @autor            Alejandro Gómez
* @projecto         Comfandi
* @descripcion      Clase para Autenticar el servicio de Expressmed 
* --------   ---   ----------   ---------------------------   ------------------------------------------------
*            No.   Fecha         Autor                        Descripcion
* --------   ---   ----------   ---------------------------   ------------------------------------------------
*            1.0   21-01-2021   Alejandro Gómez (AG)          Creacion Clase.
**************************************************************************************************************/
global with sharing class ExpressmedAuth {
    private static 	Http 					http;
    private static 	HttpRequest 			request;
    private static 	HttpResponse 			Response;
    private static 	String 					JSON_req 			{get;set;}
    private static 	String 					JSON_res 				{get;set;}
    private	static 	List<Orden_de_Servicio_SAP__c> lstReqOrdSerSAP;
    
    public ExpressmedAuth() { }
    
    @InvocableMethod
    public static void respuestaServicio(List<Id> lstids){
        System.debug('lstids#1: ' + lstids);
        respuestaLogicaInvocacion(lstids);
    }
    
    public static void respuestaLogicaInvocacion(List<Id> lstids){
        List<String> lstRecords = new List<String>();
      
        for( Orden_de_Servicio_SAP__c recor : [SELECT Id, NumeroOrdenServicio__c FROM Orden_de_Servicio_SAP__c WHERE Id IN : lstids] ){
            lstRecords.add(recor.Id);
            System.debug('lstids#2: ' + lstRecords); // Se cambia a Id.
 
        }
        doCallout(lstRecords);
    }
        
    @future (callout=true)
    global static void doCallout(List<Id> lstRecords){
        System.debug('lstids#4: ' + lstRecords);
        Configuracion_Endpoint_Expressmed_Auth__mdt param = [ SELECT Id,EndPoint__c,Metodo__c, Usuario__c, Contrasenia__c FROM Configuracion_Endpoint_Expressmed_Auth__mdt WHERE DeveloperName =: Label.WS_INVOICE_CREATE_EXPRESSMED_AUTH ];
        String email = param.Usuario__c; 
        String passwordString = param.Contrasenia__c;
        Blob temporalPasswordBlob = Blob.valueOf(passwordString);
        string encodeParamPassword = EncodingUtil.base64Encode(temporalPasswordBlob);   
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint(param.EndPoint__c); 
        request.setMethod(param.Metodo__c); 
        
        request.setTimeout(60000);
        
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('Origin', 'http://localhost:3230');
        request.setHeader('Accept-Language', 'es-co');
        request.setHeader('Platform', '2ed42ac3-e7c6-43c2-b96c-234ffebd22b9');
        
        request.setBody(
            '{'+
            '"Email": "'+email+'",'+
            '"Password": "'+encodeParamPassword+'"'+
            '}'
        );
        system.debug(' request :: ' + request);
        system.debug('   request.setBody : ' +   request.getBody());
        HttpResponse response = http.send(request);
        JSON_res = response.getBody();
        System.debug('JSON_res#5: ' + JSON_res);
        
        if( response.getStatus() == 'OK' && response.getStatusCode() == 200 ){
            fromJSON deserializadoExito = (fromJSON) JSON.deserialize(JSON_res, fromJSON.class);
            System.debug('deserializadoExito::: ' + deserializadoExito );
            getToken(deserializadoExito, lstRecords);
        }else{ 
            fromJSONOnError deserializadoError = (fromJSONOnError) JSON.deserialize(JSON_res, fromJSONOnError.class);
            System.debug('deserializadoError::: ' + deserializadoError );
            System.debug('Sin conexión.');            
        }
    }
    
    public static void getToken(fromJSON deserializadoExito, List<Id> lstRecords){
        if( deserializadoExito.data.get(0).token != null || deserializadoExito.data.get(0).token != '' ){
            String token = deserializadoExito.data.get(0).token;
            System.debug('token::: ' + token ); 
            
            try{ 
                // Llamada al segundo servicio, entrega token y cadena de ids;         
                ExpressmedCons.respuestaServicio(lstRecords, token); 
            }catch(Exception ex){
                System.debug('Se genero un problema al llamar el segundo servicio: ' + ex.getCause());
            }
        }
    }
    
    public class fromJSON{
        public cls_data[] data;
    }
    
    class cls_data {
        public String token;			//eyJhbGciOiJ...
        public String tokenExpire;		//2020-10-14T06:12:36.7239721-05:00
        public Integer id;				//0
        public String serial;			//875eaf5a-8d4c-4a48-a0e5-e3f4421ec7cf
        public String name;				//prueba
        public String email;			//correo@expressmed.co
        public String cellphone;		//+57 
        public String profileSerial;	//e38t1923-528b-431c-80a7-2ea9e6a8d502
        public Integer state;			//1
    }
    
    public class fromJSONOnError{
        public Integer ErrorType;		//1
        public String CodeMessage;		//IDENTITY.LOGINMAILPASSWORD.USERNOTEXIST
        public String Model;			// null
        public String Message;			//IDENTITY.LOGINMAILPASSWORD.USERNOTEXIST
    }
    
    public static List<Orden_de_Servicio_SAP__c> consultaOrdenServicioSAP( List<String> idSf ){
        return [SELECT Id,Contador_Pedidos__c,Descuento__c,CanalDistribucion__c,Cantidad__c,CantidadVinculacion__c,CebesCentroRecepcionaEntrega__c,CentroCosto__c,CentroLogistico__c,Cierra_Consulta_Consecutivo__c,Ciudad_de_Facturacion__c,ClaseDocumentoVentas__c,ClienteDeudor__c,CodigoMaterial__c,CodigoMaterialSAP__c,ConsecutivoOS__c,Direccion_de_Facturacion__c,Estado__c,Fecha_Factura__c,FechaInicioEvento__c,GOVERNMENTRESPONSECODE__c,GOVERNMENTRESPONSEDESCRIPTION__c,GrupoVendedor__c,Id_Transaccion__c,Identificador_unico__c,Identificador_unico_mensaje__c,InicialesGestor__c,LEGALSTATUS__c,Name,NroFacturaSAPVinculacion__c,Numero_Factura__c,NumeroOrdenServicio__c,NumeroPedido__c,Observaciones__c,OficinaVentas__c,Orden_de_Compra__c,OrdenInterna__c,OrganizacionVentas__c,Por_Vinculacion__c,PorcentajeIVA__c,PROCESSDATE__c,Retenido__c,Sector__c,SendInvoiceCreate__c,SendInvoiceStatus__c,Status_registro_monitor__c,Valor_Factura__c,ValorAntesIVA__c,ValorIVA__c,ValorTotal__c
                FROM Orden_de_Servicio_SAP__c Where Id =: idSf];
    }
}
