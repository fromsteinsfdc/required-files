trigger OnContentDocumentDelete on ContentDocument (before delete) {
    RequiredFilesController.deleteRequiredFiles(trigger.oldMap.keySet());
}