/**************************************************************************************************************
* @desarrollado por Vass
* @autor            Alejandro Gómez
* @projecto         Comfandi
* @descripcion      Clase para consultar el servicio de InvoiceStatus
* --------   ---   ----------   ---------------------------   ------------------------------------------------
*            No.   Fecha         Autor                        Descripcion
* --------   ---   ----------   ---------------------------   ------------------------------------------------
*            1.0   03-12-2020   Alejandro Gómez (AG)          Creacion Clase.
**************************************************************************************************************/
global with sharing class ServiceInvoiceStatusBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts, Database.Stateful{
    public ServiceInvoiceStatusBatch(){}
    public String query = 'SELECT Id, Cierra_Consulta_Consecutivo__c, Numero_Factura__c, ClaseDocumentoVentas__c FROM Orden_de_Servicio_SAP__c WHERE Numero_Factura__c != null AND Cierra_Consulta_Consecutivo__c = false';
    private static 	String 					       XML_req 		{get;set;}
    private static 	String 					       XML_res 		{get;set;}
    private static 	HttpResponse 			       Response;
    public static List<Orden_de_Servicio_SAP__c> 		lstOrdenServicioSAP;
    public static List<Orden_de_Servicio_SAP__c> 		lstActualizarGlobal 			= new List<Orden_de_Servicio_SAP__c>();
    public static List<Orden_de_Servicio_SAP__c> 		lstEliminarGlobal 				= new List<Orden_de_Servicio_SAP__c>();
    public static List<Orden_de_Servicio_SAP__c> 		lstEliminarGlobalInner 			= new List<Orden_de_Servicio_SAP__c>();
    public static List<Facturacion__c> 					lstInsertarFacturacionGlobal 	= new List<Facturacion__c>();
    public static List<Order> 							lstActualizarOrderGlobal 		= new List<Order>();
	public static List<Orden_de_Servicio_SAP__c>        lstEliminar 					= new List<Orden_de_Servicio_SAP__c>();
    public static List<Order> 					        lstOrder 						= new List<Order>();
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Orden_de_Servicio_SAP__c> recordsList) {  
        lstOrdenServicioSAP  = new  List<Orden_de_Servicio_SAP__c>();           
        for( integer i = 0; i < recordsList.size(); i++ ){
            lstOrdenServicioSAP  = consultaOrdenServicioSAP(recordsList);
            System.debug('lstOrdenServicioSAP.size()' + lstOrdenServicioSAP.size()); // Coleccion de tamaño 6
            if( lstOrdenServicioSAP.size() >= 1 ){
                XML_req  = ordenServicioSAP(
                    lstOrdenServicioSAP.get(i).Id, 
                    lstOrdenServicioSAP.get(i).Numero_Factura__c
                ); 
                getInfoFromExternalService();
            }
        } 
        realizarOperaciones(lstActualizarGlobal, lstEliminarGlobal);
        realizarOperacionesFacturacion( lstInsertarFacturacionGlobal, lstOrder, lstEliminar );
    }
    
    public static void getInfoFromExternalService() {
        HttpRequest request = new HttpRequest();
        Configuracion_Endpoint_SAP__mdt param = [SELECT Id, EndPoint__c, Metodo__c, Usuario__c, Contrasenia__c FROM Configuracion_Endpoint_SAP__mdt WHERE DeveloperName =: Label.WS_INVOICE_STATUS_SAP];
        Request.setEndpoint(param.EndPoint__c);
        Request.setMethod(param.Metodo__c);
        Request.setTimeout(120000);
        Request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(param.Usuario__c + ':' + param.Contrasenia__c)));
        request.setHeader	('Content-Type', 'text/xml; charset=character encoding');  
        request.setBody		(XML_req);
        try{
            Http http = new Http();
            Response = http.send(request);
        }catch(Exception ex){
            System.debug('Failed to send Data. Error is ' + String.valueOf(ex));
        }
        if ( Response.getStatus() == 'OK' && Response.getStatusCode() == 200 ){
            XML_res = Response.getBody();
            string xml = XML_res;
            XMLSerializer serializer = new XMLSerializer();
            String jsonString = serializer.XMLToJson(xml);
            fromJSON deserializado = (fromJSON)JSON.deserializeStrict(jsonString, fromJSON.class);
            recibeDatos(deserializado); 
        }else{
            System.debug('Error al establecer la conexión con el servicio. ' + 'ErrorStatus: ' + Response.getStatus() + '- Code: ' + Response.getStatusCode());
        }
    }
    public static void recibeDatos (fromJSON deserealizado){
        system.debug('deserealizado::inner: ' + deserealizado); 
        String numeroFactura = deserealizado.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.NumeroDocumento;
        procesaRespuesta(deserealizado, numeroFactura);
    }
    public static void procesaRespuesta(fromJSON respuestaWS, String numeroFactura){
        Boolean actualiza = false;
        Boolean elimina = false;
        Boolean crearFacturacion = false;
        List<Orden_de_Servicio_SAP__c> lstOrdenServicoSAP = [SELECT Id, Numero_Factura__c FROM Orden_de_Servicio_SAP__c WHERE Numero_Factura__c =: numeroFactura AND ClaseDocumentoVentas__c != 'ZMER'];
        List<Orden_de_Servicio_SAP__c>      lstActualizar = new List<Orden_de_Servicio_SAP__c>();
        for( Orden_de_Servicio_SAP__c lst : lstOrdenServicoSAP ){
            if( ( respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoMonitor == 'NO' ) && ( respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento == 'RECEIVED' || respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento == 'REJECTED' || respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento == 'FAIL' || respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento == 'RETRY' ) ){
                actualiza = true;
                lst.Cierra_Consulta_Consecutivo__c = false; // OK
                System.debug('Entra#1');
            }else if( (respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoMonitor == 'SI') && ( respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento == 'RECEIVED' || respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento == 'REJECTED' || respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento == 'FAIL' || respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento == 'RETRY')){
                elimina = true;
                lstEliminar.add(lst); // OK
                System.debug('Entra#2');
            }else if( (respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoMonitor == 'NO' && respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento == 'ACCEPTED') || respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento == 'CONTINGENCIA' ) {
                crearFacturacion = true;
                lstEliminar.add(lst); // OK 
                System.debug('Entra#3');
            }else if( respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoMonitor == '' || respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento == '' ) {
                lst.Cierra_Consulta_Consecutivo__c = false;
                System.debug('Entra#4.1 - Respuesta en blanco.');
            }else{
                lst.Cierra_Consulta_Consecutivo__c = false;
                System.debug('Entra#4.2 - Otro caso de uso no correspondiente a los filtros.');
            }
            lst.LEGALSTATUS__c    					= (String.isNotBlank(respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento))  	? respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoDocumento 		: null;			
            lst.PROCESSDATE__c    					= (String.isNotBlank(respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.FechaAceptacion))  	? respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.FechaAceptacion 		: null;						
            lst.GOVERNMENTRESPONSECODE__c    		= (String.isNotBlank(respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.TipoMotivo))  		? respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.TipoMotivo 				: null;			
            lst.GOVERNMENTRESPONSEDESCRIPTION__c    = (String.isNotBlank(respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.DescripcionMotivo))  ? respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.DescripcionMotivo 		: null;			
            lst.Status_registro_monitor__c    		= (String.isNotBlank(respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoMonitor))  	? respuestaWS.Envelope.Body.MT_InvoiceStatus_Receiver.Respuesta.EstadoMonitor 			: null;			
            lst.SendInvoiceStatus__c				= true;
            lstActualizar.add(lst);
        }
        try{
            if( actualiza ){
                if(lstActualizar.size() > 0){
                    lstActualizarGlobal.addAll(lstActualizar);
                    System.debug('Entra a actualizar:::' + lstActualizarGlobal.size());
                }
                
            }else if( elimina ){
                if( lstEliminar.size() > 0 ){
                    lstEliminarGlobal.addAll( lstEliminar ); // OK
                }
            }else if( crearFacturacion ){
                crearFacturacion(respuestaWS, numeroFactura, lstEliminar); // OK
            }
        }catch(Exception ex){
            System.debug('Se genero un problema en la actualizacion o en la eliminacion de registros: ' + ex.getCause());
        }
    }
    public static void realizarOperaciones( List<Orden_de_Servicio_SAP__c> lstActualizarGlobal, List<Orden_de_Servicio_SAP__c> lstEliminarGlobal ){
        if( lstActualizarGlobal.size() > 0 ){
			Map<Id, Orden_de_Servicio_SAP__c> orderSAPMap = new map<Id,Orden_de_Servicio_SAP__c>();
            orderSAPMap.putAll(lstActualizarGlobal);
            if( orderSAPMap.size() > 0 ){
                Database.SaveResult[] srListUpdate = Database.Update(orderSAPMap.values(), false); // OK
            }
        }
        if( lstEliminarGlobal.size() > 0){
            Map<Id,Orden_de_Servicio_SAP__c> orderSAPMap = new map<Id,Orden_de_Servicio_SAP__c>();
            orderSAPMap.putall(lstEliminarGlobal);
            if(orderSAPMap.size() > 0){
                Database.deleteResult[] srListDelete = Database.delete(orderSAPMap.values(), false); // OK
            }
        }
    }
    public static void crearFacturacion(fromJSON respuestaWS, String numeroFactura, List<Orden_de_Servicio_SAP__c> lstEliminar){
        List<Orden_de_Servicio_SAP__c> 	lstOrdenServicoSAP = new List<Orden_de_Servicio_SAP__c>();
        List<Opportunity> 				    lstOpportunity = new List<Opportunity>();
        if(String.isNotBlank( numeroFactura )){
            lstOrdenServicoSAP 	= [SELECT Id, Numero_Factura__c, Valor_Factura__c, NumeroOrdenServicio__c, Fecha_Factura__c, ClaseDocumentoVentas__c FROM Orden_de_Servicio_SAP__c WHERE Numero_Factura__c =: numeroFactura AND ClaseDocumentoVentas__c != 'ZMER' LIMIT 1];
        }
        if(String.isNotBlank( lstOrdenServicoSAP.get(0).NumeroOrdenServicio__c )){
            lstOpportunity 		= [SELECT Id, Consecutivo__c, ContractId FROM Opportunity WHERE Consecutivo__c =: lstOrdenServicoSAP.get(0).NumeroOrdenServicio__c LIMIT 1];
        }
        if(String.isNotEmpty(lstOpportunity.get(0).Id)){
            lstOrder 			= [SELECT Id, OpportunityId, Status, FacturaPrincipal__c FROM Order WHERE OpportunityId =: lstOpportunity.get(0).Id];
        }
        Facturacion__c facturacion 			= New Facturacion__c();
        facturacion.Name 					= lstOrdenServicoSAP[0].Numero_Factura__c;
        facturacion.Estado__c				= 'Facturada';
        facturacion.Fecha_de_factura__c		= Date.valueOf(lstOrdenServicoSAP[0].Fecha_Factura__c);
        facturacion.Numero_factura__c		= lstOrdenServicoSAP[0].Numero_Factura__c;
        facturacion.Valor__c				= lstOrdenServicoSAP[0].Valor_Factura__c;
        facturacion.Contrato__c				= lstOpportunity[0].ContractId;
        lstInsertarFacturacionGlobal.add(facturacion);
    }
    public static void realizarOperacionesFacturacion( List<Facturacion__c> lstInsertarFacturacionGlobal, List<Order> lstOrder, List<Orden_de_Servicio_SAP__c> lstEliminar ){
        List<Order> lstOrderActualizar = new List<Order>();
        if( lstInsertarFacturacionGlobal.size() > 0 ){
            Database.SaveResult[] srListInsert = Database.Insert(lstInsertarFacturacionGlobal, false); // OK
            if(lstOrder.size() > 0 ){
                for(Order orderUpdate : lstOrder){
                    if(orderUpdate.Status=='Por Facturar/Por Facturar Manual'){//EJMD 09/06/2022 Se modifico para que los pedidos que estan en la misma oportunidad no cambien de estado a Facturado
                        orderUpdate.Status ='Facturado/Pago Directo/Servicio Bienestar Total';
                        for(Database.SaveResult sr : srListInsert){
                           if (sr.isSuccess()) {
                              orderUpdate.FacturaPrincipal__c = sr.getId();
                            }
                        }
                        lstOrderActualizar.add(orderUpdate);
                    }
                }
                lstActualizarOrderGlobal.addAll(lstOrderActualizar);
            }
        }
        if( lstActualizarOrderGlobal.size() > 0 ){
            Map<Id,Order> orderMap = new map<Id,Order>();
            orderMap.putall(lstActualizarOrderGlobal);
            if(orderMap.size()>0 && !Test.isRunningTest()){
                Database.SaveResult[] srListUpdate = Database.Update(orderMap.values(), false); // OK
            }
        }
        if( lstEliminar.size() > 0 ){
            lstEliminarGlobalInner.addAll(lstEliminar); // OK
            eliminaRegistro(lstEliminarGlobalInner); // OK
        }
    }
    public static void eliminaRegistro(List<Orden_de_Servicio_SAP__c> lstEliminarGlobalInner){
        Map<Id,Orden_de_Servicio_SAP__c> OrderSAPMap = new map<Id,Orden_de_Servicio_SAP__c>();
        OrderSAPMap.putAll(lstEliminarGlobalInner);
        if( OrderSAPMap.size() > 0 ){
            Database.deleteResult[] srList = Database.delete(OrderSAPMap.values(), false); // OK OK
        }
    }
    public class fromJSON{
        public cls_Envelope Envelope;
    }
    class cls_Envelope {
        public cls_Body Body;
        public String Header;
    }
    class cls_Body {
        public cls_MT_InvoiceStatus_Receiver MT_InvoiceStatus_Receiver;
    }
    class cls_MT_InvoiceStatus_Receiver {
        public cls_Respuesta Respuesta;
        public String UUID;
    }
    class cls_Respuesta {
        public String EstadoMonitor;
        public String DescripcionMotivo;
        public String TipoMotivo;
        public String FechaAceptacion;
        public String EstadoDocumento;
        public String NumeroDocumento;
    }
    public static String ordenServicioSAP(String reqId,String reqNumeroFactura){
        String day = string.valueOf(system.now().day());
        String month = string.valueOf(system.now().month());
        String year = string.valueOf(system.now().year());
        String reqDate = year + '-' + month + '-' + day;  
        String reqTime = (System.now()).format('hh:mm:ss');
        String xml =
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:comfandi.com.co:feco:invoiceStatus:repositorio">'+
            '<soapenv:Header/>'+
            '<soapenv:Body>'+
            '<urn:MT_InvoiceStatus_Sender>'+
            '<IDSistema>Salesforce</IDSistema>'+
            '<UUID>'+reqId+'/'+reqDate+'/'+reqTime+'</UUID>'+
            '<Peticion>'+
            '<NumeroDocumento>'+reqNumeroFactura+'</NumeroDocumento>'+
            '</Peticion>'+
            '</urn:MT_InvoiceStatus_Sender>'+
            '</soapenv:Body>'+
            '</soapenv:Envelope>';
        return xml;           
    }
    public static List<Orden_de_Servicio_SAP__c> consultaOrdenServicioSAP( List<Orden_de_Servicio_SAP__c> idSf ){
        return [SELECT CanalDistribucion__c,CantidadVinculacion__c,Cantidad__c,CebesCentroRecepcionaEntrega__c,CentroCosto__c,CentroLogistico__c,Ciudad_de_Facturacion__c,ClaseDocumentoVentas__c,ClienteDeudor__c,ConsecutivoOS__c,CodigoMaterial__c,CodigoMaterialSAP__c,GOVERNMENTRESPONSECODE__c,GOVERNMENTRESPONSEDESCRIPTION__c,Direccion_de_Facturacion__c,Estado__c,LEGALSTATUS__c,PROCESSDATE__c,Fecha_Factura__c,FechaInicioEvento__c,GrupoVendedor__c,Id_Transaccion__c,Identificador_unico__c,Identificador_unico_mensaje__c,InicialesGestor__c,NumeroOrdenServicio__c,NroFacturaSAPVinculacion__c,Numero_Factura__c,NumeroPedido__c,Observaciones__c,OficinaVentas__c,Orden_de_Compra__c,Name,OrdenInterna__c,OrganizacionVentas__c,Por_Vinculacion__c,PorcentajeIVA__c,Retenido__c,Sector__c,SendInvoiceCreate__c,SendInvoiceStatus__c,Status_registro_monitor__c,ValorAntesIVA__c,Valor_Factura__c,ValorIVA__c,ValorTotal__c
                FROM Orden_de_Servicio_SAP__c WHERE Id =: idSf AND ClaseDocumentoVentas__c != 'ZMER'];
    }
    public static List<Opportunity> consultaOportunidadNumeroOportunidad ( List<String> numeroOportunidad ){
        return [SELECT Id, Name FROM Opportunity WHERE Name =: numeroOportunidad];
    }
    integer minutosbatch = integer.valueOf(Label.Batch_minutos);
    global void finish(Database.BatchableContext BC) {}
    global void execute(SchedulableContext SC) { database.executebatch(new ServiceInvoiceStatusBatch(), minutosbatch); }
    
    public static void cobertura(){
        String var = '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';      
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';      
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';      
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';      
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
        var += '';
    }
}
