/**
 * Utilities for Zaak integratie (case)
 */

public with sharing class ZaakService {
    //
    // Adds the content of attachments to the structure by reference
    public static void enrichZaakWithFilesByReference(List<ZaakModel> requests) {
        try {
            Set<ID> allCvIds = new Set<ID>(); // For use in query
            for(ZaakModel request : requests) {
                if(request.contentVersionIds == null) {
                    continue;
                }
                for(ID cvId : request.contentVersionIds) {
                    allCvIds.add(cvId);
                }
            }

            Set<ID> allCdIds = new Set<ID>(); // For use in query
            for(ZaakModel request : requests) {
                if(request.contentDocumentIds == null) {
                    continue;
                }
                for(ID cdId : request.contentDocumentIds) {
                    allCdIds.add(cdId);
                }
            }
            //
            // Get all contentversions from the database, hope it fits in heap
            Map<Id,ContentVersion> cvRecordMap = new Map<Id, ContentVersion>([SELECT Id, VersionData, FileExtension, FileType, PathOnClient, Title, Description FROM ContentVersion WHERE Id IN :allCvIds]);
            Map<Id,ContentVersion> cdRecordMap = new Map<Id, ContentVersion>();
            for(ContentVersion cv : [SELECT Id, VersionData, FileExtension, FileType, PathOnClient, Title, Description, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :allCdIds AND IsLatest=true]) {
                cdRecordMap.put(cv.ContentDocumentId, cv);
            }
            //
            // Iterate the request map and add attachments to the request
            for(ZaakModel zm : requests) {
                //
                // Enrich the structure with contentversion data
                zm.informatieobjecten = new List<InformatieObjectModel>();
                if(zm.contentVersionIds <> null) {
                    for (ID cvId : zm.contentVersionIds) {
                        if (cvRecordMap.containsKey(cvId)) {
                            InformatieObjectModel iom = getModel(cvRecordMap.get(cvId));
                            zm.informatieobjecten.add(iom);
                        }
                    }
                }
                if(zm.contentDocumentIds <> null) {
                    for(ID cdId : zm.contentDocumentIds) {
                        if(cdRecordMap.containsKey(cdId)) {
                            InformatieObjectModel iom = getModel(cdRecordMap.get(cdId));
                            zm.informatieobjecten.add(iom);
                        }
                    }
                }
            }
        } catch (Exception ex) {
            ApexFaultHandler.publishError(ex, 'ZaakService' ,'enrichZaakWithFilesByReference');
        }
    }
    //
    // Converts the contentdocumentversion to the JSON values the service needs
    public static InformatieObjectModel getModel(ContentVersion cv) {
        InformatieObjectModel output = new InformatieObjectModel();
        output.bestand = SharedUtils.replaceNullWithEmptyString(EncodingUtil.base64Encode(cv.VersionData));
        output.beschrijving = SharedUtils.replaceNullWithEmptyString(cv.Title);
        //output.beschrijving = SharedUtils.replaceNullWithEmptyString(cv.Description);
        output.formaat = SharedUtils.replaceNullWithEmptyString(cv.FileType);
        return output;
    }

}