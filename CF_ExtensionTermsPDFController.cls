public with sharing class CF_ExtensionTermsPDFController {
    public Id recordId;
    public String email;
    public String medium;
    public Boolean isPrimary;
    public String status;
    public String contactAuth;
    public String caseNumber;
    public Boolean isTrue;
    public Case ocase { get; set; }
    public List<CF_ExtensionTerms__c> approvedExtTermsList { get; set; }
    public List<ContactPointEmail> contactPointEmailList { get; set; }
    public static Case ocaseP { get; set; }
    public static List<CF_ExtensionTerms__c> approvedExtTermsListP { get; set; }
    public static List<ContactPointEmail> contactPointEmailListP { get; set; }
    public CF_ExtensionTermsPDFController (){}
    public CF_ExtensionTermsPDFController(ApexPages.StandardController controller) {
        this.recordId = (Id)controller.getId();
        this.ocase = [SELECT Id, Account.Name, CaseNumber, CreatedDate, Account.CF_ClientNumberEnelCodensa__c, CF_Submotive__c FROM Case WHERE Id =: recordId];
        this.approvedExtTermsList = [SELECT Id, Name, LastModifiedDate, CF_ExtensionDays__c, createdby.Alias, CF_MediumNotificationExtension__c, SystemModStamp FROM CF_ExtensionTerms__c WHERE Caso__c = :this.ocase.Id Order By SystemModStamp DESC LIMIT 1];
        contactPointEmailList = [SELECT Id, IsPrimary, CF_Status__c, CF_ContactAuthorization__c, ParentId, EmailAddress FROM ContactPointEmail WHERE ParentId = : this.ocase.AccountId and IsPrimary = true and CF_Status__c = 'Activo' and CF_ContactAuthorization__c = 'Si' LIMIT 1];
    }
    public void getDataFuntionality(List<String> recordId){
        ocaseP = [SELECT Id, Account.Name, CaseNumber, CreatedDate, Account.CF_ClientNumberEnelCodensa__c, CF_Submotive__c FROM Case WHERE Id = :recordId[0]];
        approvedExtTermsListP = [SELECT Id, Name, LastModifiedDate, CF_ExtensionDays__c, createdby.Alias, CF_MediumNotificationExtension__c, SystemModStamp FROM CF_ExtensionTerms__c WHERE Caso__c = : ocaseP.Id Order By SystemModStamp DESC LIMIT 1];
        contactPointEmailListP = [SELECT Id, IsPrimary, CF_Status__c, CF_ContactAuthorization__c, ParentId, EmailAddress FROM ContactPointEmail WHERE ParentId = : ocaseP.AccountId and IsPrimary = true and CF_Status__c = 'Activo' and CF_ContactAuthorization__c = 'Si' LIMIT 1];
        if(contactPointEmailListP.size() > 0){
            email = contactPointEmailListP[0].EmailAddress;    
            isPrimary = contactPointEmailListP[0].IsPrimary;
            status = contactPointEmailListP[0].CF_Status__c;
            contactAuth = contactPointEmailListP[0].CF_ContactAuthorization__c;
        }
        medium = approvedExtTermsListP[0].CF_MediumNotificationExtension__c;
        caseNumber = ocaseP.CaseNumber;
        String recordIdx = recordId[0];
        PageReference reportPage = Page.ExtensionTermsPDFView;
        reportPage.getParameters().put('id', recordIdx);
        Blob reportPdf;
        try {
            reportPdf = reportPage.getContentAsPDF();
        }
        catch (Exception e) {
            reportPdf = Blob.valueOf(e.getMessage());
        }
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String headerEmailUrl = PageReference.forResource('headerEmail').getUrl();
        String footerEmailUrl = PageReference.forResource('footerEmail').getUrl();
        if(medium == 'Correo electronico' && isPrimary == true && status == 'Activo' && contactAuth == 'Si' && email != null){
            try{
                Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                emailAttachment.setContentType('application/pdf');
                emailAttachment.setFileName('PDF - Ampliación de Términos.pdf');
                emailAttachment.body = reportPdf;
                emailAttachment.setInline(false);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { email });
                String setBccAddresses = System.Label.SetBccAddresses;
                String[] sendingToBccAdd = new String[]{ setBccAddresses };
                mail.setBccAddresses( sendingToBccAdd );
                mail.setSubject('PDF - Ampliación de Terminos');
                String messageBody ='<html style="overflow-y: hidden;"><head><title></title></head><body style="height: auto; min-height: auto;"><img alt="headerEmail" src="' + baseUrl + headerEmailUrl + '" style="max-width: 677.2123474121094px" title="headerEmail" /><br /><br /><br /><span style="font-family:Arial,Helvetica,sans-serif;">Bogot&aacute;, D.C, ' + System.now().format('dd/MM/yyyy') + '.<br /><br /><span style="background:#ffffff">Estimado cliente,</span></span><br /><br /><span style="background:#ffffff"><span style="font-family:&quot;Times New Roman&quot;"><span style="font-size:11,0000pt"><span style="font-family:Calibri"><span style="color:#000000">Adjuntamos comunicaci&oacute;n que contiene informaci&oacute;n importante para ti acerca del caso No.&nbsp;' + caseNumber + '.</span></span></span></span></span><br /><br /><span style="background:#ffffff"><span style="font-family:&quot;Times New Roman&quot;"><span style="font-size:11,0000pt"><span style="font-family:Calibri"><span style="color:#000000">Te recordamos que esta direcci&oacute;n de E-mail es utilizada solamente para los env&iacute;os de la informaci&oacute;n solicitada. Por favor no respondas con consultas personales ya que no podr&aacute;n ser respondidas. Si lo deseas puedes comunicarte con nosotros en la l&iacute;nea de atenci&oacute;n 601 7 421 115 o cont&aacute;ctenos en la p&aacute;gina Web </span></span></span><u><span style="font-size:11,0000pt"><span style="font-family:Calibri"><span style="color:#548dd4"><span style="text-decoration:underline"><span style="text-underline:single">www.creditofacilcodensa.com.</span></span></span></span></span></u></span></span><br /><br /><span style="background:#ffffff"><span style="font-family:&quot;Times New Roman&quot;"><span style="font-size:11,0000pt"><span style="font-family:Calibri"><span style="color:#000000">Cordialmente,</span></span></span></span></span><br /><br /><span style="background:#ffffff"><span style="font-family:&quot;Times New Roman&quot;"><span style="font-size:11,0000pt"><span style="font-family:Calibri"><span style="color:#000000">Cr&eacute;dito F&aacute;cil Codensa.</span></span></span></span></span><br />&nbsp;<div><span style="font-size:9px;"><span style="font-family:Arial,Helvetica,sans-serif;"><span style="color:#404040">La Defensor&iacute;a del Consumidor Financiero para la compa&ntilde;&iacute;a Scotiabank Colpatria S.A., est&aacute; ubicada en la Avenida Carrera 19 No. 114-09 Oficina 502, Bogot&aacute; D.C., Tel: 601 213-1322 y 601 213-1370 en Bogot&aacute; D.C., atenci&oacute;n de lunes a viernes de 8:00 a.m. a 5:00 p.m (d&iacute;as h&aacute;biles). Correo electr&oacute;nico: defensoriasc@pgabogados.com; Defensor del consumidor financiero Principal: Jos&eacute; Guillermo Pe&ntilde;a Gonz&aacute;lez, Defensor Suplente: Carlos Alfonso Cifuentes Neira. Para mayor informaci&oacute;n relacionada con las funciones, asuntos de competencia, funci&oacute;n de conciliador y otros aspectos de la Defensor&iacute;a del Consumidor Financiero, consulta www.creditofacilcodensa.com secci&oacute;n Canales de atenci&oacute;n link Defensor&iacute;a del Consumidor Financiero.&rdquo;</span></span></span><br /><img alt="Picture2" src="' + baseUrl + footerEmailUrl + '" style="max-width: 675.91015625px" title="Picture2" /></div></body></html>';
                mail.setHtmlBody(messageBody);
                mail.setFileAttachments( new Messaging.EmailFileAttachment[] { emailAttachment });
                Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail });            
            }
            catch(exception ex){
                System.debug('Email: ' + ex.getMessage());
            }
        }
        try{
            ContentVersion docVer = new ContentVersion(); 
            docVer.ContentLocation = 'S';
            docVer.PathOnClient  = 'PDF-Ampliación de Terminos.pdf'; 
            docVer.Title = 'PDF-Ampliación de Terminos.pdf' ;
            docVer.DocumentType_fileupload__c = 'TIP012';
            Blob pdfBodyAttach = reportPdf;
            DocVer.VersionData = pdfBodyAttach;
            insert docVer;
            String versId = [Select ContentDocumentId From ContentVersion Where Id =:docVer.Id].ContentDocumentId;
            ContentDocumentLink docLink = new ContentDocumentLink();
            docLink.ContentDocumentId = versId;
            docLink.LinkedEntityId = recordIdx;
            docLink.ShareType = 'I';
            docLink.Visibility = 'AllUsers';
            insert docLink; 
            WS_SmartUpdateClaim.createdRequestFuture(recordIdx);
        }
        catch(exception ex){
            System.debug('Document: ' + ex.getMessage());
        }
    } 
    @InvocableMethod(label='GetDataExtensionTermPDF' description='Returns the necessary data to send the pdf and attach to the case.')
    public static void getData(List<String> recordId){
        CF_ExtensionTermsPDFController getDataF = new CF_ExtensionTermsPDFController();
        getDataF.getDataFuntionality(recordId);
    }
}
