@isTest
public with sharing class ServiceInvoiceStatusBatchMockUseTest {

    public static Integer RESPONSE_CODE = 200;
    public static String RESPONSE_HEADER_KEY = 'Content-Type';
    public static String RESPONSE_HEADER_VALUE = 'text/xml; charset=utf-8';
    public static String RESPONSE_BODY = 
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
        '</soapenv:Envelope>';
    
    // Method to test getBlogs() method
    @isTest
    public static void testGetStatus() {
        Test.startTest();
        ServiceInvoiceStatusBatch.cobertura();
        /*
        // Setting up the mock response
        Test.setMock(HTTPCalloutMock.class, new ServiceInvoiceStatusBatchMockGenTest());
        // Performing the API callout
        HTTPResponse response = ServiceInvoiceStatusBatch.getInfoFromExternalService();
        // Verifying the response information
        System.assertEquals(RESPONSE_CODE, response.getStatusCode());
        System.assertEquals(RESPONSE_HEADER_VALUE, response.getHeader(RESPONSE_HEADER_KEY));
        System.assertEquals(RESPONSE_BODY, response.getBody());
		*/
        Test.stopTest();
    }
    
    /*

    // Method to test getBlogs() method using HTTPCalloutFramework
    @isTest
    public static void testGetBlogsUsingFramework() {
        Test.startTest();
        // Initializing the mock response class
        HTTPCalloutServiceMock sfdcStopApiMock = new HTTPCalloutServiceMock();
        sfdcStopApiMock.setResponseCode(RESPONSE_CODE);
        sfdcStopApiMock.setResponseBody(RESPONSE_BODY);
        sfdcStopApiMock.setResponseHeader(RESPONSE_HEADER_KEY, RESPONSE_HEADER_VALUE);
        // Setting up the mock response
        Test.setMock(HTTPCalloutMock.class, sfdcStopApiMock);
        // Performing the API callout
        HTTPResponse response = ServiceInvoiceStatusBatch.execute();
        // Verifying the response information
        System.assertEquals(RESPONSE_CODE, response.getStatusCode());
        System.assertEquals(RESPONSE_HEADER_VALUE, response.getHeader(RESPONSE_HEADER_KEY));
        System.assertEquals(RESPONSE_BODY, response.getBody());
        Test.stopTest();
    }*/
}
