import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { createTSANetCaseNote, getNewAccessToken, toast } from 'c/tsaNetHelper'

export default class TsaNetCaseAddNote extends NavigationMixin(LightningElement) {

    isLoading = false

    @api isQuickAction = false
    @api tsaNetCaseId 
    @api caseId
    note = {}

    handleCreateNote(){
        this.note['priority'] = 'Low'
        console.log(JSON.stringify(this.note))
        this.isLoading = true
        let caseRecordId = this.caseId + ''
        let json = JSON.stringify(this.note)
        createTSANetCaseNote(caseRecordId, json)
        .then(response => {
            console.log('response : ', response)
            this.isLoading = false
            if(response){
                toast(this, 'Success', 'success', 'The Note have been created successfully!')
                this.handleClose()
            }
        }).catch(error => {
            if(error.body.message == 'Unauthorized'){
                getNewAccessToken().then(res => {
                    console.log('res: ', res)
                    createTSANetCaseNote(caseRecordId, json)
                    .then(response => {
                        console.log('response : ', response)
                        this.isLoading = false
                        if(response){
                            toast(this, 'Success', 'success', 'The Note have been created successfully!')
                            this.handleClose()
                        }
                    })
                })
            }
        })
    }
    
    handleChangeField(event){
        this.note[event.target.name] = event.target.value
    }

    handleClose(){
        if(!this.isQuickAction){
            this.dispatchEvent(new CustomEvent('close'))
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.tsaNetCaseId,
                    //objectApiName: 'Case',
                    actionName: 'view'
                }
            })
        }
    }
}