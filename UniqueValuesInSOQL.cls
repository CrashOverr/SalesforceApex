 List<zip__c> lstzips= [select id,name,ANNUAL_CALLS__c,city__c,state__c,No_Of_Targets__c,Territory_ID__c,Territory__r.name,Territory__r.ANNUAL_CALLS__c from zip__c where name in :sArr ];

 Map<String,zip__c> mapStrByzip=new Map<String,zip__c>();

for(zip__c zipone:lstzips){
    mapStrByLstzips.put(zipone.Territory_ID__c,zipone);//This is map and hence it will always have unique values 
}

system.debug('List return'+mapStrByLstzips.values());
