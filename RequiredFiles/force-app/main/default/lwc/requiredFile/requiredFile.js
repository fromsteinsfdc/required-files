import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import fileStatus from '@salesforce/apex/RequiredFilesController.fileStatus';
import handleFileUpload from '@salesforce/apex/RequiredFilesController.handleFileUpload';

export default class RequiredFile extends NavigationMixin(LightningElement) {
    @api fieldName;
    @api label;
    @api helptext;
    @api fileTypes;
    @api forceName;
    @api recordId;
    @track contentVersion = {};
    fileSize;
    @track fileId;
    @track requiredFile;
    @track version;
    @track fileImageUrl;
    disabled = false;

    connectedCallback() {
        console.log('in ccb()');
        console.log(this.recordId, this.fieldName);
        console.log(this.forceName);
        //this.fieldName = 'Response_Received__c';
        this.loadRequiredFile();
    }

    loadRequiredFile() {
        console.log('in loadRequiredFile', this.fieldName, this.recordId);
        //if (this.fieldName) {
            fileStatus({ recordId: this.recordId, fieldName: this.fieldName })
                .then(result => {
                    console.log('result='+JSON.stringify(result));
                    if (result) {
                        this.requiredFile = result.reqFile;
                        this.contentVersion = result.version;
                        this.fileImageUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=thumb120by90&versionId='+ result.version.Id;                        
                        console.log(JSON.stringify(this.contentVersion.ContentModifiedBy));
                    }
                })
                .catch(error => {
                    console.log('Error calling attached file', JSON.stringify(error));
                });
        //}
    }

    openFile(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                recordIds: this.requiredFile.File_ID__c
            }
        });
    }

    handleUploadFinished(event) {
        console.log('in handleUploadFinished');
        // Get the list of uploaded files
        const files = event.detail.files;
        if (files.length != 1) {
            // Handle error, should only be 1 file
            throw 'Unexpected error: expected input is one file';
        }
        handleFileUpload({ recordId: this.recordId, fieldName: this.fieldName, fileId: files[0].documentId, overwriteName: this.forceName })
            .then(result => {
                console.log('success calling apex handleUploadFinished', JSON.stringify(result));
                this.loadRequiredFile();
                updateRecord({fields: {Id : this.recordId}});
                getRecordNotifyChange([{ recordId: this.recordId }]);
            })
            .catch(error => {
                console.log('Error calling apex handleUploadFinished', JSON.stringify(error));
            });
    }  
}