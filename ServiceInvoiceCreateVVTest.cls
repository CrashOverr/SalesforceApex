@isTest (seeAllData=true)
global class ServiceInvoiceCreateVVTest {
    
    @isTest static void testProcesoSolicitudCredito_1(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ServiceInvoiceCreateTestMock()); 
        ServiceInvoiceCreateVV obj = new ServiceInvoiceCreateVV();
        VV_Solicitud_de_Vivienda_SAP__c ordenSAP = [SELECT Id, Name , VV_Numero_Solicitud_de_Vivienda__c FROM VV_Solicitud_de_Vivienda_SAP__c LIMIT 1];
        List<String> lstOrdenSAP = new List<String>();
        lstOrdenSAP.add(ordenSAP.Id);
        ServiceInvoiceCreateVV.respuestaServicio(lstOrdenSAP);
        Test.stopTest();
    }
    @isTest 
    static void ServiceInvoiceCreateTest1(){
        Orden_de_Servicio_SAP__c ordenSAPNuevo = new Orden_de_Servicio_SAP__c();
        ordenSAPNuevo.ClaseDocumentoVentas__c = 'ZCON';
        ordenSAPNuevo.OrganizacionVentas__c	 = '1000';
        ordenSAPNuevo.CanalDistribucion__c = '45';
        ordenSAPNuevo.Sector__c = '10';
        ordenSAPNuevo.OficinaVentas__c = '02';
        ordenSAPNuevo.GrupoVendedor__c = '002';
        ordenSAPNuevo.ClienteDeudor__c = '75742';
        ordenSAPNuevo.CodigoMaterial__c = '8800813';
        ordenSAPNuevo.Cantidad__c = '1';
        ordenSAPNuevo.ValorAntesIVA__c = '462436.97';
        ordenSAPNuevo.CentroLogistico__c = '1327';
        ordenSAPNuevo.NumeroOrdenServicio__c = 'MVP-7275';
        ordenSAPNuevo.Identificador_unico__c	 = 'OS-DS-0049727';
        ordenSAPNuevo.Retenido__c = false;
        ordenSAPNuevo.Direccion_de_Facturacion__c = 'CLL 26 # 21 - 20';
        ordenSAPNuevo.Ciudad_de_Facturacion__c = 'TULUA';
        ordenSAPNuevo.Orden_de_Compra__c = '000';
        ordenSAPNuevo.Descuento__c = '0.00';
        ordenSAPNuevo.Contador_Pedidos__c = 1;
        insert ordenSAPNuevo;
    }
    
    global class ServiceInvoiceCreateTestMock implements HttpCalloutMock{   
        global HTTPResponse respond(HTTPRequest Request) {
            HttpResponse response = new HttpResponse();
            Configuracion_Endpoint_SAP__mdt param = [SELECT Id, EndPoint__c, Metodo__c, Usuario__c, Contrasenia__c FROM Configuracion_Endpoint_SAP__mdt WHERE DeveloperName =: Label.WS_INVOICE_CREATE_SAP];
            Request.setEndpoint(param.EndPoint__c);
            Request.setMethod(param.Metodo__c);
            Request.setTimeout(120000);
            Request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(param.Usuario__c + ':' + param.Contrasenia__c)));
            Request.setHeader('Content-Type', 'text/xml; charset=character encoding');
            response.setBody(
                '<SOAP:Envelope xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/"><SOAP:Header/><SOAP:Body xmlns:urn="urn:comfandi.com.co:feco:invoiceCreate:repositorio"><ns0:MT_InvoiceCreate_Receiver xmlns:ns0="urn:comfandi.com.co:feco:invoiceCreate:repositorio"><UUID>a2A11000002sBOcEAM/2020-12-20/04:42:33</UUID><Respuesta><NumeroFactura>0003501128</NumeroFactura><FechaFactura>2020-12-20</FechaFactura><ValorFactura>5502750.0000 </ValorFactura><NumeroPedido>DOA-17320</NumeroPedido><IdTransaccion>dcb74862ce2547d59b80a2a0af12c560</IdTransaccion></Respuesta><Mensajes><Tipo_mensaje>S</Tipo_mensaje><Texto_mensaje>Documento 0003501128 grabado.</Texto_mensaje></Mensajes><Mensajes><Tipo_mensaje>I</Tipo_mensaje><Texto_mensaje>Proceso Finalizado</Texto_mensaje></Mensajes></ns0:MT_InvoiceCreate_Receiver></SOAP:Body></SOAP:Envelope>'
            );
            response.setStatusCode(200);
            response.setStatus('OK');
            return response; 
        }
    }
    
    @isTest static void servicioDataCreditoWS(){
        test.starttest();
        ServiceInvoiceCreate.cobertura();
        test.stopTest();
    }
}
