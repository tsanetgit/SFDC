import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation"

import getAllRelatedFiles from '@salesforce/apex/TSANetUtils.getAllRelatedFiles'
import getAttachmentConfig from '@salesforce/apex/TSANetService.getAttachmentConfig'
import sendAttachment from '@salesforce/apex/TSANetService.sendAttachment'
 
export default class UploadAttachment extends NavigationMixin(LightningElement) {

    @api recordId
    @api record

    isDone = false
    hasConfig = false
    isLoading = true

    @api isQuickAction

    @track contentVersions = []
    @track files = []

    connectedCallback(){
        if(this.record?.tsanet_connect__Token__c){
            this.isLoading = true
            console.log('record token : ', this.record?.tsanet_connect__Token__c)
             getAttachmentConfig({ token: this.record?.tsanet_connect__Token__c }).then(response => {
                console.log('response : ', response)
                let config = JSON.parse(response)
                console.log('config : ', config)

                if(config?.receiver?.parameters?.password){
                    this.hasConfig = true

                    getAllRelatedFiles({ caseId: this.record?.Id }).then(contentVersions => {
                        console.log('contentVersions, ', contentVersions)
                        contentVersions.forEach(cv => {
                            cv['isSelected'] = false
                        })
                        this.contentVersions = contentVersions
                    })

                }
                this.isLoading = false

            }).catch(error => {
                console.log('error : ', error)
                this.isLoading = false
            })
        }
       
    }

    handleFileChange(event) {
        let files = event.target.files;

        console.log('files : ', files)
        console.log('files : ', JSON.stringify(files))

        for (const [key, file] of Object.entries(files)) {
            console.log('file : ', file)
            if (file) {
                const reader = new FileReader();
                reader.onload = () => {
                    let fileData = {
                        fileId: file.name + '-' + file?.size,
                        filename: file.name,
                        base64: reader.result.split(',')[1]
                    };

                    this.files.push(fileData)

                    console.log('this.fileData : ', JSON.stringify(fileData))
                };
                reader.readAsDataURL(file);
            }
        }
    }

    handleDeleteFile(event){
        let fileId = event.currentTarget.dataset.fileId

        console.log('fileName : ', fileId)

        let found = this.files.find(file => ( file.fileId == fileId ))

        if(found?.cvId){
            this.contentVersions.forEach(cv => {
                if(cv.Id == found?.cvId){
                    cv['isSelected'] = !cv['isSelected']
                }
            })
        }

        this.files = this.files.filter(file => ( file.fileId != fileId ))
    }

    handleUpload() {
        if (this.files.length) {
            console.log('record token : ', this.record?.tsanet_connect__Token__c)

            this.isLoading = true

            sendAttachment({ token: this.record?.tsanet_connect__Token__c, files: this.files }).then(response => {
                console.log('response, ', response)

                let results = JSON.parse(response)

                results.forEach(result => {
                    this.files.forEach(file => {
                        if(file?.filename == result?.fileName){
                            file['resultIconName'] = result?.receiverStatus == 'SUCCESS' ? 'action:approval' : 'action:close'
                            file['resultMessage'] = result?.receiverMessage
                        }
                    })
                })

                this.isDone = true
                this.isLoading = false

            }).catch(error => {
                console.log('error : ', error)
                this.isLoading = false
            })
            
        }
    }

    handleSelectContentVersion(event){
        let cvId = event.currentTarget.dataset.id
        console.log('cvId : ', cvId)

        this.contentVersions.forEach(cv => {
            if(cv.Id == cvId){
                cv['isSelected'] = !cv['isSelected']

                if(cv.isSelected){
                    this.files.push({
                        filename: cv.Title,
                        base64: undefined,
                        fileId: cv.Id,
                        cvId: cv.Id
                    })
                } 
                    
            }
        })
    }


    get unSelectedFiles(){
        return this.contentVersions.filter(item => !item?.isSelected)
    }

    get relatedFilesTitle(){
        return 'Related Files (' + this.contentVersions.length + ') '
    }

    get selectedFilesTitle(){
        return 'Selected Files (' + this.files.length + ') '
    }

    get receivedCompanyName(){
        return this.record?.tsanet_connect__receivedCompanyName__c
    }

    get closeButtonLabel(){
        return this.isDone ? 'Done' : 'Close'
    }

    handleClose(){
        this.handleCloseWindow(true)
    }

    handleCloseWindow(isRefresh){
        console.log('isQuickAction: ', this.isQuickAction)
        this.clearState()
        if(!this.isQuickAction){
            console.log('isRefresh: ', isRefresh)
            this.dispatchEvent(new CustomEvent('close', {
                detail: {
                    refresh: isRefresh
                }
            }))
        } else {

            this[NavigationMixin.Navigate]({    
                type: "standard__recordPage",
                attributes: {
                    recordId: this.recordId,
                    actionName: "view"
                }
            })
            //location.reload()
            this.dispatchEvent(new CustomEvent('close'))
        }
    }

    clearState(){
        this.record = undefined
        this.isLoading = false
        this.isDone = false
        this.files = []
    }

/*

    get acceptedFormats() {
        return ['.pdf', '.png', '.docx'];
    }

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        console.log('No. of files uploaded : ' + uploadedFiles.length);

        for (const [key, file] of Object.entries(uploadedFiles)) {
            console.log('file : ', file)
            if (file) {
                const reader = new FileReader();
                reader.onload = () => {
                    let fileData = {
                        filename: file.name,
                        base64: reader.result.split(',')[1]
                    };

                    this.files.push(fileData)

                    console.log('this.fileData : ', JSON.stringify(fileData))
                };
                reader.readAsDataURL(file);
            }
        }
    }
        */
}