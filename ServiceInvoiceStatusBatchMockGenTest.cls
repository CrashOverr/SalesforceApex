@isTest
global class ServiceInvoiceStatusBatchMockGenTest implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        System.assertEquals('http://181.118.157.53:50000/XISOAPAdapter/MessageServlet?senderParty=&senderService=COMFNSAFO_Q&receiverParty=&receiverService=BS_ACONCAGUA_QAS_520&interface=SI_InvoiceStatus_Out&interfaceNamespace=urn:comfandi.com.co:feco:invoiceStatus:repositorio', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();

        res.setHeader('Content-Type', 'text/xml; charset=utf-8');
        res.setBody(
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:comfandi.com.co:feco:invoiceStatus:repositorio">'+
        '<soapenv:Header/>'+
        '<soapenv:Body>'+
        '<urn:MT_InvoiceStatus_Sender>'+
        '<IDSistema>Salesforce</IDSistema>'+
        '<UUID></UUID>'+
        '<Peticion>'+
        '<NumeroDocumento></NumeroDocumento>'+
        '</Peticion>'+
        '</urn:MT_InvoiceStatus_Sender>'+
        '</soapenv:Body>'+
        '</soapenv:Envelope>'        
        );
        res.setStatusCode(200);
        return res;
    }
}
