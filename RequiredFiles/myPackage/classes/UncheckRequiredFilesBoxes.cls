public class UncheckRequiredFilesBoxes implements Queueable {

    private String objectName;
    private Map<String, List<Id>> fieldnameRecordsMap;

    public UncheckRequiredFilesBoxes(String objectName, Map<String, List<Id>> fieldnameRecordsMap) {
        this.objectName = objectName;
        this.fieldnameRecordsMap = fieldnameRecordsMap;
    }

    public void execute(QueueableContext context) {
        String fieldString='';
        List<Id> recordIds = new List<Id>();    
        for (String fieldName : fieldnameRecordsMap.keySet()) {
            fieldString += fieldName+',';
            recordIds.addAll(fieldnameRecordsMap.get(fieldName));
        }
        fieldString = fieldString.substring(0, fieldString.length()-1);
        List<SObject> records = Database.query('SELECT '+ fieldString+' FROM '+objectName+' WHERE Id IN: recordIds');

        for (SObject record : records) {
            for (String fieldName : fieldnameRecordsMap.keySet()) {
                if (fieldnameRecordsMap.get(fieldName).contains(record.Id)) {
                    record.put(fieldName, false);
                }
            }
        }
        update records;    
    }
}
