public class RequiredFilesController {

    public class RequiredFilesException extends Exception {}    

    @AuraEnabled
    public static RequiredFileResult fileStatus(Id recordId, String fieldName) {
        System.debug('in fileAttached');
        /* This code is left over from when fieldName wasn't required, but it is now
        String queryString = 'SELECT Id';
        if (fieldName != null) {
            queryString += ', '+ fieldName;
        }
        queryString += ' FROM '+ recordId.getSObjectType()+' WHERE Id = :recordId';
        */
        String queryString = 'SELECT '+ fieldName +' FROM '+ recordId.getSObjectType() +' WHERE Id = :recordId';

        SObject parentRecord = Database.query(queryString);
        List<Required_File__c> reqFiles = [SELECT Id, Record_ID__c, File_ID__c, Field_Name__c FROM Required_File__c WHERE Record_ID__c =: recordId AND Field_Name__c =: fieldName];
        
        if (reqFiles.size() > 1) {
            System.debug('Error: found more than one Required File record');
            throw new RequiredFilesException('Error: found more than one Required File record, expected one or zero records');
        }
        if (reqFiles.size() == 0) {
            System.debug('No matching Required File record');
            return null;
        }

        Required_File__c reqFile = reqFiles[0];
        ContentVersion version = [SELECT Id, ContentDocumentId, ContentSize, ContentModifiedDate, Title, FileExtension, ContentModifiedById, ContentModifiedBy.Name FROM ContentVersion WHERE ContentDocumentId =: reqFile.File_ID__c AND IsLatest = true LIMIT 1];
        if (version == null) {
            System.debug('Error: A matching Required File record has been found, but ContentVersion ID '+reqFile.File_ID__c+' could not be found');
            throw new RequiredFilesException('Error: A matching Required File record has been found, but ContentVersion ID '+reqFile.File_ID__c+' could not be found');
        }
        return new RequiredFileResult(reqFile, version);
    }

    @AuraEnabled
    //public static SObject handleFileUpload(Id recordId, String fieldName, String fileId, String fileName) {
    public static SObject handleFileUpload(Id recordId, String fieldName, String fileId, String overwriteName) {
    //public static SObject handleFileUpload(Id recordId, String fieldName) {
        System.debug('in handleFileUpload');
        if (overwriteName != null) {
            System.debug('overwriting filename with '+overwriteName);
            ContentDocument uploadedFile = [SELECT Title FROM ContentDocument WHERE Id =: fileId];
            System.debug('uploadedFile = '+ uploadedFile);
            uploadedFile.Title = overwriteName;
            update uploadedFile;
            System.debug('uploadedFile = '+ uploadedFile);
        }

        DescribeSObjectResult objDescribe = recordId.getSObjectType().getDescribe();
        SObject parentRecord;
        if (fieldName != null) {
            parentRecord = Database.query('SELECT '+ fieldName+' FROM '+ objDescribe.getName()+' WHERE Id = :recordId');
            parentRecord.put(fieldName, true);
            System.debug('parentRecord = '+ parentRecord);
            update parentRecord;
        }

        Required_File__c requiredFile = new Required_File__c();
        requiredFile.Record_ID__c = recordId;
        requiredFile.Field_Name__c = fieldName;
        requiredFile.File_ID__c = fileId;
        requiredFile.Object_Name__c = objDescribe.getName();
        requiredFile.Full_Field_Name__c = objDescribe.getName()+'.'+fieldName;
        insert requiredFile;

        return parentRecord;
    }


    public static void deleteRequiredFiles(List<Id> fileIds) {
        System.debug('in deleterequiredfiles');
        List<Required_File__c> reqFiles = [SELECT Id, Record_ID__c, File_ID__c, Field_Name__c FROM Required_File__c WHERE File_ID__c IN: fileIds];
        System.debug('reqFiles = '+reqFiles);
        List<SObject> recordsToUpdate = new List<SObject>();
        Map<String, String> recordFieldMap = new Map<String, String>();
        Map<String, Map<String, List<Id>>> dataMap = new Map<String, Map<String, List<Id>>>();
    
        System.debug('about to loop through reqFiles');
        for (Required_File__c reqFile : reqFiles) {
            String objectName = Id.valueOf(reqFile.Record_ID__c).getSObjectType().getDescribe().getName();
            System.debug('objectName = '+ objectName);
            String fieldName = reqFile.Field_Name__c;
            System.debug('fieldName = '+ fieldName);

            if (!dataMap.containsKey(objectName)) {
                dataMap.put(objectName, new Map<String, List<Id>>());
            }
            Map<String, List<Id>> fieldnameRecordsMap = new Map<String, List<Id>>();
            List<Id> recordIds = new List<Id>();
            recordIds.add(reqFile.Record_ID__c);
            if (dataMap.get(objectName).containsKey(fieldName)) {
                recordIds.addAll(dataMap.get(objectName).get(fieldName));
            }
            fieldnameRecordsMap.put(fieldName, recordIds);
            System.debug('fieldnameRecordsMap = '+ fieldnameRecordsMap);
            dataMap.put(objectName, fieldNameRecordsMap);
            //recordFieldMap.put(reqFile.Record_ID__c, reqFile.Field_Name__c);
        }
        delete reqFiles;
    
        for (String objectName : dataMap.keySet()) {
            System.debug('about to enqueue uncheckboxes');
            UncheckRequiredFilesBoxes queueJob = new UncheckRequiredFilesBoxes(objectName, dataMap.get(objectName));
            System.enqueueJob(queueJob);
        }                
    }
    
    public static void deleteRequiredFiles(Set<Id> idSet) {
        List<Id> idList = new List<Id>();
        idList.addAll(idSet);
        deleteRequiredFiles(idList);
    }

    public class RequiredFileResult {
        @AuraEnabled public Required_File__c reqFile;
        @AuraEnabled public ContentVersion version;

        public RequiredFileResult(Required_File__c reqFile, ContentVersion version) {
            this.reqFile = reqFile;
            this.version = version;
        }
    }


    /*
    public static String getNameField(DescribeSObjectResult sobjDescribe) {
        Map<String, SObjectField> fields = sobjDescribe.fields.getMap();
        if (!fields.containsKey('Name') || !fields.get('Name').getDescribe().isNameField())
        {
            for (String fieldName : fields.keySet()) {
                if (fields.get(fieldName).getDescribe().isNameField())
                    return fieldName;
                
            }
        }
        return 'Name';
    }

    public static String getNameField(SObjectType sobjType) {
        return getNameField(sobjType.getDescribe());
    }

    public static String getNameField(String objectName) {
        return getNameField(Schema.getGlobalDescribe().get(objectName).getDescribe());
        
    }
    */
}
