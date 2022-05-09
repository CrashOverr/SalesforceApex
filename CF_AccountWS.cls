@RestResource(urlMapping='/Accounts/*')
global with sharing class CF_AccountWS {
    @HttpGet
    global static Account getAccountById() {
        RestRequest request = RestContext.request;
        // Grab the Account from the end of the URL
        String accountId = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1 );
        Account result =  [SELECT Id,CF_Stratum__c,FinServ__Gender__pc,FinServ__Occupation__pc,FinServ__Status__c,CF_LastStatusDate__c,
                           CF_OriginationDate__c,CF_ClientNumberEnelCodensa__c,FirstName,MiddleName,LastName,Suffix,CF_DocumentType__c,
                           CF_DocumentNumber__c
                           FROM Account WHERE Id = :accountId WITH SECURITY_ENFORCED];
        return result;
    }
    @HttpPost
    global static String createAccount( CF_AccountWS.accountWrapper wrpAccounts ) {
        if (wrpAccounts != null) {
            Account  thisAccount = new Account();
            thisAccount.CF_ActivityOccupation__c=String.valueOf(wrpAccounts.occupation);
            thisAccount.CF_AmparatedClient__c=String.valueOf(wrpAccounts.amparateClient);
            thisAccount.CF_AttackVictim__c=wrpAccounts.attackVictim;
            thisAccount.CF_AuthorizeDataProcessing__pc=String.valueOf(wrpAccounts.authorizeDataProcessing);
            //thisAccount.CF_BankProcessingDate__c=wrpAccounts.bankProcessingDate; No existe
            thisAccount.CF_CatShopping6MonthsLast__c=String.valueOf(wrpAccounts.catShopping6MonthsLast);
            thisAccount.CF_ClientNumberEnelCodensa__c=String.valueOf(wrpAccounts.clientNumberEnelCodensa);
            thisAccount.CF_ClientStatus__c=String.valueOf(wrpAccounts.clientStatus);
            thisAccount.CF_CLVSegment__c=String.valueOf(wrpAccounts.CLVSegment);
            thisAccount.CF_CompanyEconomicActivity__c=String.valueOf(wrpAccounts.companyEconomicActivity);
            thisAccount.CF_CompanyName__c=String.valueOf(wrpAccounts.companyName);
            thisAccount.CF_CompanyPhone__c=String.valueOf(wrpAccounts.companyPhone);
            thisAccount.CF_ConflictVictim__c=String.valueOf(wrpAccounts.conflictVictim);
            thisAccount.CF_ContactPreferenceChannel__c=String.valueOf(wrpAccounts.contactPreferenceChannel);
            thisAccount.CF_ContractType__c=String.valueOf(wrpAccounts.contractType);
            thisAccount.CF_CutoffDate__c=Date.valueOf(wrpAccounts.cutoffDate.format());
            thisAccount.CF_Dependents__c=String.valueOf(wrpAccounts.dependents);
            thisAccount.CF_Disability__c=wrpAccounts.disability;
            thisAccount.CF_DisabilityDescription__c=String.valueOf(wrpAccounts.disabilityDescription);
            //thisAccount.CF_DocumentIssueDate__c=wrpAccounts.documentIssueDate;
            thisAccount.CF_DocumentNumber__c=String.valueOf(wrpAccounts.documentNumber);
            thisAccount.CF_DocumentType__c=String.valueOf(wrpAccounts.documentType);
            thisAccount.CF_EducationLevel__c=String.valueOf(wrpAccounts.educationLevel);
            thisAccount.CF_FamilyHolderPEP__c=wrpAccounts.familyHolderPEP;
            thisAccount.CF_FinancialMargin__c=wrpAccounts.financialMargin;
            thisAccount.CF_FinancialModifiedDate__c=Datetime.valueOf(wrpAccounts.financialModifiedDate.format());
            thisAccount.CF_ForeignCurrencyTransaction__c=String.valueOf(wrpAccounts.foreignCurrencyTransaction);
            thisAccount.CF_FundsSource__c=wrpAccounts.fundsSource;
            thisAccount.CF_HasPensionAllowanceCertificate__c=wrpAccounts.hasPensionAllowanceCertificate;
            //thisAccount.CF_IsDataUpdate__c=wrpAccounts.isDataUpdate; No existe
            thisAccount.CF_LaborOld__c=wrpAccounts.laborOld;
            thisAccount.CF_LaborSectionLastModificationDate__c=Datetime.valueOf(wrpAccounts.laborSectionLastModificationDate.format());
            thisAccount.CF_LaborStatus__c=String.valueOf(wrpAccounts.laborStatus);
            thisAccount.CF_LastStatusDate__c=Date.valueOf(wrpAccounts.lastStatusDate.format());
            thisAccount.CF_LGBTIQ__c=wrpAccounts.LGBTIQ;
            thisAccount.CF_MonthTimeResidence__c=wrpAccounts.monthTimeResidence;
            thisAccount.CF_NIT__c=String.valueOf(wrpAccounts.NIT);
            thisAccount.CF_NotContactable__c=wrpAccounts.notContactable;
            thisAccount.CF_NotContactableMotive__c=String.valueOf(wrpAccounts.notContactableMotive);
            thisAccount.CF_OriginationDate__c=Date.valueOf(wrpAccounts.originationDate.format());
            thisAccount.CF_OriginationHour__c=wrpAccounts.originationHour;
            thisAccount.CF_OriginationObservations__c=String.valueOf(wrpAccounts.originationObservations);
            thisAccount.CF_OriginationPoint__c=String.valueOf(wrpAccounts.originationPoint);
            //thisAccount.CF_OriginationResult__c=wrpAccounts.originationResult; No existe
            thisAccount.CF_OriginationType__c=String.valueOf(wrpAccounts.originationType);
            thisAccount.CF_PEPHolder__c=wrpAccounts.PEPHolder;
            thisAccount.CF_PortfolioBalance__c=wrpAccounts.portfolioBalance;
            thisAccount.CF_Profession__c=String.valueOf(wrpAccounts.profession);
            thisAccount.CF_PublicRecognition__c=String.valueOf(wrpAccounts.publicRecognition);
            thisAccount.CF_PYGSegment__c=String.valueOf(wrpAccounts.PYGSegment);
            thisAccount.CF_ResidenceAbroad__c=String.valueOf(wrpAccounts.residenceAbroad);
            thisAccount.CF_SecondNationalityCountry__c=String.valueOf(wrpAccounts.secondNationalityCountry);
            thisAccount.CF_SixMonthsInColombia__c=String.valueOf(wrpAccounts.sixMonthsInColombia);
            thisAccount.CF_SpecialProtection__c=String.valueOf(wrpAccounts.specialProtection);
            thisAccount.CF_StatusNumberClientEnelCodensa__c=String.valueOf(wrpAccounts.statusNumberClientEnelCodensa);
            thisAccount.CF_Stratum__c=String.valueOf(wrpAccounts.stratum);
            thisAccount.CF_TypeHouse__c=String.valueOf(wrpAccounts.typeHouse);
            thisAccount.CF_WatchLists__c=String.valueOf(wrpAccounts.watchLists);
            thisAccount.FinServ__Gender__pc=String.valueOf(wrpAccounts.gender);
            thisAccount.FinServ__MaritalStatus__pc=String.valueOf(wrpAccounts.civilStatus);
            thisAccount.FirstName=String.valueOf(wrpAccounts.firstName);
            thisAccount.LastName=String.valueOf(wrpAccounts.lastName);
            thisAccount.MiddleName=String.valueOf(wrpAccounts.middleName);
            thisAccount.Suffix=String.valueOf(wrpAccounts.suffix);
            insert thisAccount;
            return thisAccount.Id;        

        }
    }
        
        
        
        
    @HttpDelete
    global static void deleteAccount() {
        RestRequest request = RestContext.request;
        String accountId = request.requestURI.substring(
            request.requestURI.lastIndexOf('/')+1);
        Account thisAccount = [SELECT Id FROM Account WHERE Id = :accountId WITH SECURITY_ENFORCED];
        delete thisAccount;
    }   
    @HttpPut
    global static ID upsertAccount( String IdAccount,String firstName,String middleName,String lastName,String suffix,String documentType,
                                   String documentNumber,String stratum,String gender,String occupation,String status,
                                   String clientNumberEnelCodensa ) {
                                       Account thisAccount = new Account(
                                           Id=IdAccount,
                                           FirstName = firstName,
                                           MiddleName = middleName,
                                           LastName = lastName,
                                           Suffix = suffix,
                                           CF_DocumentType__c = documentType,
                                           CF_DocumentNumber__c = documentNumber,
                                           CF_Stratum__c = stratum,
                                           FinServ__Gender__pc = gender,
                                           CF_ActivityOccupation__c = occupation,
                                           FinServ__Status__c = status,
                                           CF_ClientNumberEnelCodensa__c = clientNumberEnelCodensa             
                                       );
        // Match account by Id, if present.
        // Otherwise, create new account.
        upsert thisAccount;
        // Return the account Id.
        return thisAccount.Id;
    }
    @HttpPatch
    global static ID updateAccountFields() {
        RestRequest request = RestContext.request;
        String accountId = request.requestURI.substring(
            request.requestURI.lastIndexOf('/')+1);
        Account thisAccount = [SELECT Id FROM Account WHERE Id = :accountId];
        // Deserialize the JSON string into name-value pairs
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        // Iterate through each parameter field and value
        for(String fieldName : params.keySet()) {
            // Set the field and value on the account sObject
            thisAccount.put(fieldName, params.get(fieldName));
        }
        update thisAccount;
        return thisAccount.Id;
    }
    //Wrapper class to accept all input parameters
    global class accountWrapper {
        String occupation;
        String amparateClient;
        Boolean attackVictim;
        String authorizeDataProcessing;
        //String bankProcessingDate; No existe
        String catShopping6MonthsLast;
        String clientNumberEnelCodensa;
        String clientStatus;
        String CLVSegment;
        String companyEconomicActivity;
        String companyName;
        String companyPhone;
        String conflictVictim;
        String contactPreferenceChannel;
        String contractType;
        Date cutoffDate;
        String dependents;
        Boolean disability;
        String disabilityDescription;
        String documentIssueDate;
        String documentNumber;
        String documentType;
        String educationLevel;
        Boolean familyHolderPEP;
        Decimal financialMargin;
        Datetime financialModifiedDate;
        String foreignCurrencyTransaction;
        Decimal fundsSource;
        Boolean hasPensionAllowanceCertificate;
        //String isDataUpdate; No existe
        Decimal laborOld;
        Datetime laborSectionLastModificationDate;
        String laborStatus;
        Date lastStatusDate;
        Boolean LGBTIQ;
        Decimal monthTimeResidence;
        String NIT;
        Boolean notContactable;
        String notContactableMotive;
        Date originationDate;
        Time originationHour;
        String originationObservations;
        String originationPoint;
        //String originationResult; // No existe
        String originationType;
        Boolean PEPHolder;
        Decimal portfolioBalance;
        String profession;
        String publicRecognition;
        String PYGSegment;
        String residenceAbroad;
        String secondNationalityCountry;
        String sixMonthsInColombia;
        String specialProtection;
        String statusNumberClientEnelCodensa;
        String stratum;
        String typeHouse;
        String watchLists;
        String gender;
        String civilStatus;
        String firstName;
        String lastName;
        String middleName;
        String suffix;
    }
    
}
