@isTest
public class RequiredFilesControllerTest {

    @isTest 
    public static void doTest() {
        Account testAcc = new Account(Name='Test');
        String testFieldName = 'TEST_Checkbox__c';
        testAcc.put(testFieldName, false);
        insert testAcc;
        RequiredFilesController.RequiredFileResult resultNoFile = RequiredFilesController.fileStatus(testAcc.Id, testFieldName);
        System.assertEquals(resultNoFile, null);


        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv;
        Id newFileId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;

        System.debug('about to call hFU - '+ testAcc.Id +' - '+ testFieldName +' - '+newFileId);
        SObject sobj = RequiredFilesController.handleFileUpload(testAcc.Id, testFieldName, newFileId, 'Overwritten');
        System.assertEquals(sobj.get(testFieldName), true);        

        Required_File__c newRF = [SELECT Record_ID__c, Field_Name__c, File_ID__c FROM Required_File__c WHERE Record_Id__c =: testAcc.Id AND Field_Name__c =: testFieldName];
        System.debug('newRF = '+ newRF);
        System.assertEquals(newRF.File_ID__c, newFileId);

        RequiredFilesController.RequiredFileResult resultWithFile = RequiredFilesController.fileStatus(testAcc.Id, testFieldName);
        System.debug(resultWithFile);
        System.assertEquals(resultWithFile.reqFile.Id, newRF.Id);
        System.assertEquals(resultWithFile.version.Id, cv.Id);  
        
        List<Id> fileIds = new List<Id>();
        fileIds.add(newFileId);
        Test.startTest();
        delete [SELECT Id FROM ContentDocument WHERE Id = :newFileId];
        //RequiredFilesController.deleteRequiredFiles(fileIds);
        Test.stopTest();
        Id accId = testAcc.Id;
        SObject updatedObject = Database.query('SELECT '+ testFieldName+' FROM Account WHERE Id = :accId');
        System.assertEquals(updatedObject.get(testFieldName), false);   
        
        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.entityName = 'Account';
        GetObjectCheckboxes chk = new GetObjectCheckboxes(context);
        chk.getDefaultValue();
        chk.getValues();
    }

}
