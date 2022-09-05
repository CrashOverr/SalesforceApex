/**************************************************************************************************************
* @desarrollado por Vass
* @autor            Alejandro Gómez
* @projecto         Comfandi
* @descripcion      Clase para el envio de la factura|documento al servicio de Expressmed 
* --------   ---   ----------   ---------------------------   ------------------------------------------------
*            No.   Fecha         Autor                        Descripcion
* --------   ---   ----------   ---------------------------   ------------------------------------------------
*            1.0   21-01-2021   Alejandro Gómez (AG)          Creacion Clase.
**************************************************************************************************************/
global with sharing class ExpressmedCons {
    private static  Http                    http;
    private static  HttpRequest       Request;
    private static  HttpResponse     Response;
    private static  String                  JSON_reqCuerpo    {get;set;}
    private static  String                  JSON_reqItem        {get;set;}
    private static  String                  JSON_res                {get;set;}
    private static  List<Orden_de_Servicio_SAP__c> lstReqOrdSerSAP;
    public ExpressmedCons() { }
    public static void respuestaServicio(List<Id> lstids, String token){
        respuestaLogicaInvocacion(lstids, token);
    }
    
    public static void respuestaLogicaInvocacion(List<Id> lstids, String token){
        List<String>                                  lstRecords                                         = new List<String>();
        List<Decimal>                              lstRecordsContador                           = new List<Decimal>();
        List<Id>                                        lstRecordsElegidos                            = new List<Id>();
        List<Orden_de_Servicio_SAP__c> lstConsultaNumeroPedido                = new List<Orden_de_Servicio_SAP__c>();
        List<Orden_de_Servicio_SAP__c> lstConsultaNumeroPedidoContador = new List<Orden_de_Servicio_SAP__c>();
        
        for( Orden_de_Servicio_SAP__c recor : [SELECT Id, NumeroOrdenServicio__c, Contador_Pedidos__c FROM Orden_de_Servicio_SAP__c WHERE Id IN : lstids] ){
            lstRecords.add(recor.NumeroOrdenServicio__c);
            lstRecordsContador.add(recor.Contador_Pedidos__c);
        }
        lstConsultaNumeroPedidoContador = consultaOrdenServicioSAPPorNumeroPedido(lstRecords);
        lstConsultaNumeroPedido = consultaOrdenServicioSAPPorNumeroPedido(lstRecords);
        List<Orden_de_Servicio_SAP__c> lstvalidacion = new List<Orden_de_Servicio_SAP__c>();
        Boolean retenidosSiCall = false;
        for(String recor3 : lstRecords ){
            Integer contador = 0;
            lstvalidacion = new List<Orden_de_Servicio_SAP__c>();
            for(Orden_de_Servicio_SAP__c record2 : lstConsultaNumeroPedido){
                if(recor3 == record2.NumeroOrdenServicio__c){
                    contador += 1;
                    lstvalidacion.add(record2);
                }
            }
            
            if( contador == 1 && lstvalidacion[0].Retenido__c == false ){
                lstRecordsElegidos.add(lstvalidacion[0].Id); 
            }else if(contador > 1){
                Boolean retenidosSi = false;                
                for(Orden_de_Servicio_SAP__c recorreLstvalidacion : lstvalidacion){                    
                    if(recorreLstvalidacion.Retenido__c == true){  
                        retenidosSi = true;                        
                        retenidosSiCall = true;                    
                    }
                }                
                if(!retenidosSi && lstConsultaNumeroPedido.size() == lstConsultaNumeroPedidoContador[0].Contador_Pedidos__c){ 
                    for(Orden_de_Servicio_SAP__c agregarIds : lstvalidacion){                        
                        lstRecordsElegidos.add(agregarIds.Id);  

                    }                
                }
            }
        }
        if(!retenidosSiCall){
            servicioInvoiceCreateRepos(lstRecordsElegidos, token );
        }
        else{
        }
    }
    
    public static void servicioInvoiceCreateRepos(List<Id> lstids, String token){
        lstReqOrdSerSAP  = new  List<Orden_de_Servicio_SAP__c>();  
        lstReqOrdSerSAP  = consultaOrdenServicioSAP(lstids);
        JSON_reqCuerpo = '';
    	integer i = 0;
       
        if( lstReqOrdSerSAP.size() >= 1 ){
            JSON_reqCuerpo  = ordenServicioExpressmedCuerpo(
                lstReqOrdSerSAP.get(0).Id,
                lstReqOrdSerSAP.get(0).NumeroOrdenServicio__c,
                lstReqOrdSerSAP.get(0).Orden_de_Compra__c,
                lstReqOrdSerSAP.get(0).Tipo_de_documento__c,
                lstReqOrdSerSAP.get(0).Numero_de_documento__c,                
                lstReqOrdSerSAP.get(0).Codigo_punto_de_venta__c,                
                lstReqOrdSerSAP.get(0).Observaciones__c,
                lstReqOrdSerSAP.get(0).Descuento_total__c,
                lstReqOrdSerSAP.get(0).Cargos_Domicilios__c,
                lstReqOrdSerSAP.get(0).PLU__c,
                lstReqOrdSerSAP.get(0).Descripcion_de_partida__c,
                lstReqOrdSerSAP.get(0).Seccion__c,
                lstReqOrdSerSAP.get(0).Cantidad__c,
                lstReqOrdSerSAP.get(0).ValorAntesIVA__c,
                lstReqOrdSerSAP.get(0).Exento__c,
                lstReqOrdSerSAP.get(0).Impuesto_al_consumo__c,
                lstReqOrdSerSAP.get(0).PorcentajeIVA__c,
                lstReqOrdSerSAP.get(0).Descuento__c,
                lstReqOrdSerSAP.get(0).NumeroPedido__c); 
       }
        System.debug('JSON_reqCuerpo::102: ' + JSON_reqCuerpo);
        doCallout(JSON_reqCuerpo, token);
        
    }
    
    global static void doCallout(String JSON_reqCuerpo, String token){
        Http http = new Http(); 
        HttpRequest request = new HttpRequest();
        Configuracion_Endpoint_Expressmed_Cons__mdt param = [ SELECT Id,EndPoint__c,Metodo__c FROM Configuracion_Endpoint_Expressmed_Cons__mdt WHERE DeveloperName =: Label.WS_INVOICE_CREATE_EXPRESSMED_CONS ];
        request.setEndpoint(param.EndPoint__c); 
        request.setMethod(param.Metodo__c); 
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('Content-Length', '0');
        request.setHeader('Origin', 'http://localhost:3230');
        request.setHeader('Accept-Language', 'es-co');
        request.setHeader('Platform', '2ed42ac3-e7c6-43c2-b96c-234ffebd22b9');
        request.setHeader('Authorization', 'Bearer ' + token);     
        request.setBody(JSON_reqCuerpo);
        
        System.debug('request::120: ' + request.getBody());
        
        try{
            Response = http.send(request);
        }
        catch(Exception ex){
            System.debug('Failed to send Data. Error is ' + String.valueOf(ex));
            return;
        }
        recibeDatos(); 
    }
    
    public static void recibeDatos(){
        JSON_res = Response.getBody();
        if( Response.getStatus() == 'OK' && Response.getStatusCode() == 200 ){
            fromJSONOnSuccess deserealizado = (fromJSONOnSuccess)JSON.deserializeStrict(JSON_res, fromJSONOnSuccess.class);
            
            System.debug('deserealizado OK 200###');
            System.debug('transactionClientId: ' + deserealizado.data[0].transactionClientId);
            System.debug('transactionSerial: ' 	   + deserealizado.data[0].transactionSerial);
            System.debug('initialDateProcess: '   + deserealizado.data[0].initialDateProcess);
            System.debug('endDateProcess: '     + deserealizado.data[0].endDateProcess);
            System.debug('sendProcessSerial: ' + deserealizado.data[0].sendProcessSerial);
.         }
        else{
            fromJSONOnError deserealizado = (fromJSONOnError)JSON.deserialize(JSON_res, fromJSONOnError.class);
            System.debug('deserealizado ON ERROR');
            System.debug('ErrorType: ' 		  + deserealizado.data[0].ErrorType);
            System.debug('CodeMessage: ' + deserealizado.data[0].CodeMessage);
            System.debug('Model: ' 			   + deserealizado.data[0].Model);
            System.debug('Message: ' 		 + deserealizado.data[0].Message);
        }        
    }

    public class fromJSONOnSuccess{
        public cls_dataOn[] data;
    }
    class cls_dataOn {
        public String transactionClientId; // salesforce-1
        public String transactionSerial;    // 85f8b899-150e-4c34-8704-3867f190d2b7
        public String initialDateProcess;  // 2020-11-16T09:24:30
        public String endDateProcess;    // 2020-11-16T09:24:30.2855823-05:00
        public String sendProcessSerial; // 427a4a87-f736-4bdb-a14e-497890bb4176
    }
    
    
    public class fromJSONOnError{
        public cls_dataOff[] data;
    }
    class cls_dataOff {
        public Integer ErrorType;       // 1
        public String CodeMessage; // IDENTITY.LOGINMAILPASSWORD.USERNOTEXIST
        public String Model;             // null
        public String Message;         // IDENTITY.LOGINMAILPASSWORD.USERNOTEXIST
    }
    
    public static String ordenServicioExpressmedCuerpo(String reqId,
                                                                                         String reqNumeroOrdenServicio,
                                                                                         String reqOrdenCompra,
                                                                                         String reqTipoDocumento,
                                                                                         String reqNumeroDocumento,
                                                                                         String reqCodigoPuntoVenta,
                                                                                         String reqObservaciones,
                                                                                         String reqDescuentoTotal,
                                                                                         String reqCargosDomicilios,
                                                                                         String reqPLU,
                                                                                         String reqDescripcionPartida,
                                                                                         String reqSeccion,
                                                                                         String reqCantidad,
                                                                                         String reqValorAntesIVA,
                                                                                         Boolean reqExento,
                                                                                         Boolean reqImpuestoConsumo,
                                                                                         String reqPorcentajeIVA,
                                                                                         String reqDescuento,
                                                                                         String reqNumeroPedido){

        String day = string.valueOf(system.now().day());
        String month = string.valueOf(system.now().month());
        String year = string.valueOf(system.now().year());
        String reqDate = year + '-' + month + '-' + day;  
        String reqTime = (System.now()).format('hh:mm:ss');
		String tipoDocumento= (reqTipoDocumento=='(N) NIT'?'NIT':reqTipoDocumento=='(C) CEDULA CIUDADANIA'?'CC':reqTipoDocumento=='(E) CEDULA EXTRANJERIA'?'CE':reqTipoDocumento);
        
        String json=        '{'+
        '"TransactionId": "'+reqId+'",'+
        '"Documents": ['+
        '{'+
        '    "Opportunity": {'+
        '      "Code": "'+reqNumeroOrdenServicio+'"'+
        //'      "Date": ""'+ // NA
        '    },'+
        '    "Order": {'+
        '      "Code": "'+reqOrdenCompra+'"'+
        //'      "Date": ""'+ // NA
        '    },'+
        '    "Adcquirer": {'+
        '      "DocumentType": "'+validarNullString(tipoDocumento)+'",'+ 
        '      "Identification": "'+validarNullString(reqNumeroDocumento)+'"'+
        '    },'+
        '    "CostCenterCode": "'+validarNullString(reqCodigoPuntoVenta)+'",'+
        '    "Remissions":['+     
        '    {'+
        '       "Code": "'+validarNullString(reqNumeroPedido)+  '",'+
		//'       "Date": ""'+ // NA
		'       "Items": [ '+
		'       {'+ 
        '          "PluCode":"'+reqPLU+ '",'+
		'          "Description": "'+validarNullString(reqDescripcionPartida)+ '",'+
		'          "SectionCode": "'+validarNullString(reqSeccion) +'",'+
		'          "Quantity": '+Integer.valueOf(reqCantidad)+','+
		'          "UnitValue": '+Integer.valueOf(reqValorAntesIVA)+ ','+
		'          "UnitOfMeasurement": "UD",'+
		'          "ExentRate":' +reqExento+ ','+
		'          "IsConsumptionTax": '+reqImpuestoConsumo+','+
		'          "PercentTax": '+validarNullString_Integer(reqPorcentajeIVA)+','+
		'          "DiscountValue":  '+validarNullString_Integer(reqDescuento)+
		'       }'+
	  	'    ]'+
        '    }'+
	  	'    ],'+
        '    "Observations": "'+validarNullString(reqObservaciones)+'",'+
        '    "PaymentMethods": ['+
        '    {'+
		'          	"Code": "",'+ 
		'          	"Value": ""'+ 
		'    }'+
        '    ],'+
        '    "DiscountValue": '+validarNullString_Integer(reqDescuentoTotal)+','+
        '    "AdvanceValue": '+validarNullString_Integer(reqCargosDomicilios)+
        '  }'+
        ']'+
        '}';
        return json;
    }
   
    public static List < Orden_de_Servicio_SAP__c > consultaOrdenServicioSAP(List < String > idSf) { 
        return [SELECT Id, Contador_Pedidos__c, Descuento__c, CanalDistribucion__c, Cantidad__c, CantidadVinculacion__c, CebesCentroRecepcionaEntrega__c,Descripcion_de_partida__c,Exento__c,CreatedDate,
                CentroCosto__c, CentroLogistico__c, Cierra_Consulta_Consecutivo__c, Ciudad_de_Facturacion__c, ClaseDocumentoVentas__c, ClienteDeudor__c,Tipo_de_documento__c,Numero_de_documento__c,
                CodigoMaterial__c, CodigoMaterialSAP__c, ConsecutivoOS__c, Direccion_de_Facturacion__c, Estado__c, Fecha_Factura__c, FechaInicioEvento__c,Codigo_punto_de_venta__c,
                GOVERNMENTRESPONSECODE__c, GOVERNMENTRESPONSEDESCRIPTION__c, GrupoVendedor__c, Id_Transaccion__c, Identificador_unico__c, Identificador_unico_mensaje__c,Seccion__c,
                InicialesGestor__c, LEGALSTATUS__c, Name, NroFacturaSAPVinculacion__c, Numero_Factura__c, NumeroOrdenServicio__c, NumeroPedido__c, Observaciones__c,Impuesto_al_consumo__c,Tipo_de_impuesto__c,
                OficinaVentas__c, Orden_de_Compra__c, OrdenInterna__c, OrganizacionVentas__c, Por_Vinculacion__c, PorcentajeIVA__c, PROCESSDATE__c, Retenido__c,Descuento_total__c,Cargos_Domicilios__c,
                Sector__c, SendInvoiceCreate__c, SendInvoiceStatus__c, Status_registro_monitor__c, Valor_Factura__c, ValorAntesIVA__c, ValorIVA__c, ValorTotal__c, PLU__c
                FROM Orden_de_Servicio_SAP__c 
                WHERE Id =: idSf 
                AND ClaseDocumentoVentas__c = 'ZMER']; 
    }
    public static List < Orden_de_Servicio_SAP__c > consultaOrdenServicioSAPPorNumeroPedido(List < String > numeroPedido) { 
        return [SELECT Id, Contador_Pedidos__c, Descuento__c, CanalDistribucion__c, Cantidad__c, CantidadVinculacion__c, CebesCentroRecepcionaEntrega__c,Descripcion_de_partida__c,Exento__c,CreatedDate,
                CentroCosto__c, CentroLogistico__c, Cierra_Consulta_Consecutivo__c, Ciudad_de_Facturacion__c, ClaseDocumentoVentas__c, ClienteDeudor__c,Tipo_de_documento__c,Numero_de_documento__c,
                CodigoMaterial__c, CodigoMaterialSAP__c, ConsecutivoOS__c, Direccion_de_Facturacion__c, Estado__c, Fecha_Factura__c, FechaInicioEvento__c,Codigo_punto_de_venta__c,
                GOVERNMENTRESPONSECODE__c, GOVERNMENTRESPONSEDESCRIPTION__c, GrupoVendedor__c, Id_Transaccion__c, Identificador_unico__c, Identificador_unico_mensaje__c, Seccion__c,
                InicialesGestor__c, LEGALSTATUS__c, Name, NroFacturaSAPVinculacion__c, Numero_Factura__c, NumeroOrdenServicio__c, NumeroPedido__c, Observaciones__c,Impuesto_al_consumo__c,Tipo_de_impuesto__c,
                OficinaVentas__c, Orden_de_Compra__c, OrdenInterna__c, OrganizacionVentas__c, Por_Vinculacion__c, PorcentajeIVA__c, PROCESSDATE__c, Retenido__c,Descuento_total__c,Cargos_Domicilios__c,
                Sector__c, SendInvoiceCreate__c, SendInvoiceStatus__c, Status_registro_monitor__c, Valor_Factura__c, ValorAntesIVA__c, ValorIVA__c, ValorTotal__c, PLU__c
                FROM Orden_de_Servicio_SAP__c 
                WHERE NumeroOrdenServicio__c =: numeroPedido 
                AND ClaseDocumentoVentas__c = 'ZMER']; 
    }
    public static String validarStringEspecial(String valor) { if (valor == null || valor == '' || valor == '0.00') { return ''; } else { return valor; } }
    public static String validarNullString(String valor) { if (valor == null || valor == '') { return ''; } else { return valor; } }
    public static Integer validarNullString_Integer(String valor){ if(valor == null || valor == ''){ return 0; }else{ return Integer.valueOf(valor); } }
    public static Integer validarNullString_IntegerZero(String valor){ if(valor == null || valor == ''){ return 1; }else{ return Integer.valueOf(valor); } }
}
