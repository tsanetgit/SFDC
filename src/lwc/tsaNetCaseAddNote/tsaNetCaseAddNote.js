import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { createTSANetCaseNote, getNewAccessToken, toast } from 'c/tsaNetHelper'

export default class TsaNetCaseAddNote extends NavigationMixin(LightningElement) {

    isLoading = false

    @api isQuickAction = false
    @api tsaNetCaseId 
    @api caseId
    @api currentUser

    priority = 'MEDIUM'
    
    priorities = [
        { label: 'Low', value: 'LOW' },
        { label: 'Medium', value: 'MEDIUM' },
        { label: 'High', value: 'HIGH' }
    ]

    note = {}

    handleCreateNote(){
        console.log(JSON.stringify(this.note))

        this.note['priority'] = this.priority
        this.note['submittedBy'] = {
            "firstName": this.currentUser?.FirstName,
            "lastName": this.currentUser?.LastName
        }

        console.log(JSON.stringify(this.note))

        if(!this.note?.summary || !this.note?.description){
            toast(this, 'Warning', 'warning', 'Please fill in all fields!')
            return;
        }

        this.isLoading = true
        let caseRecordId = this.caseId + ''
        let json = JSON.stringify(this.note)

        createTSANetCaseNote(caseRecordId, json)
        .then(response => {
            console.log('response : ', response)
            
            if(response){
                toast(this, 'Success', 'success', 'The Note have been created successfully!')
                this.isLoading = false
                this.handleCloseWindow(true)
            }
        }).catch(error => {
            console.error('error : ', error)
        })
    }
    
    handleChangeField(event){
        let text = event?.target?.value
        let fieldName = event?.target?.name
        if(text.includes('class="')){
            text = text.replace(/\s*class="[^"]*"/g, '');
        }
        this.note[fieldName] = text
    }

    handleChangePriority(event){
        this.priority = event.target.value
    }

    handleClose(){
        this.handleCloseWindow(false)
    }

    handleCloseWindow(isRefresh){
        console.log('isRefresh: ', isRefresh)
        console.log('this.tsaNetCaseId : ', this.tsaNetCaseId)
        if(!this.isQuickAction){
            console.log('isRefresh: ', isRefresh)
            this.dispatchEvent(new CustomEvent('close', {
                detail: {
                    refresh: isRefresh
                }
            }))
        } else {
            console.log('here')
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.tsaNetCaseId,
                    objectApiName: 'tsanet_connect__TSANetCase__c',
                    actionName: 'view'
                }
            })
        }
    }

    
}