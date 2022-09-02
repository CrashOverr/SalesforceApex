public class FileController {
    @AuraEnabled(cacheable=true)
    public static FilesWrapper[] getFilesList(Id recordId) {
        FilesWrapper[] filesList = new List<FilesWrapper>{};
            for (ContentDocumentLink link : [
                SELECT
                ContentDocumentId,
                ContentDocument.LatestPublishedVersion.Title,
                ContentDocument.LatestPublishedVersion.CF_ClassificationF__c,
                ContentDocument.LatestPublishedVersion.CF_DocumentTypeF__c
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
            ]) {
                filesList.add(
                    new FilesWrapper(
                        link.ContentDocumentId,
                        link.ContentDocument.LatestPublishedVersion.Title,
                        link.ContentDocument.LatestPublishedVersion.CF_ClassificationF__c,
                        link.ContentDocument.LatestPublishedVersion.CF_DocumentTypeF__c
                    )
                );
            }
        return filesList;
    } 

    @AuraEnabled(cacheable=true)
    public static FilesWrapper[] getFilesAllList(Id recordId) {
        FilesWrapper[] filesAllList = new List<FilesWrapper>{};
            for (ContentDocumentLink link : [
                SELECT
                ContentDocumentId,
                ContentDocument.LatestPublishedVersion.Title,
                ContentDocument.LatestPublishedVersion.CF_ClassificationF__c,
                ContentDocument.LatestPublishedVersion.CF_DocumentTypeF__c
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
            ]) {
                filesAllList.add(
                    new FilesWrapper(
                        link.ContentDocumentId,
                        link.ContentDocument.LatestPublishedVersion.Title,
                        link.ContentDocument.LatestPublishedVersion.CF_ClassificationF__c,
                        link.ContentDocument.LatestPublishedVersion.CF_DocumentTypeF__c
                    )
                );
            }
        return filesAllList;
    } 

    public virtual class File{
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public String classification { get; set; }        
        @AuraEnabled
        public String documentType { get; set; }
        public File(String id, String title, String classification, String documentType) {
            this.id = id;
            this.title = title;
            this.classification = classification;
            this.documentType = documentType;
        }
    }
    
    public class FilesWrapper extends File{
        public FilesWrapper(String id, String title, String classification, String documentType) {
            super(id, title, classification, documentType);
        }
    }
    
    @AuraEnabled
    public static Id createContentDocLink(Id contentVersionId, Id recordId) {
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId].ContentDocumentId;
        insert new ContentDocumentLink(ContentDocumentId = docId, LinkedEntityId = recordId);
        return docId;
    }
}
