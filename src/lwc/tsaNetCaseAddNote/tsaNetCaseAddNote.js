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

        this.isLoading = true
        let caseRecordId = this.caseId + ''
        let json = JSON.stringify(this.note)
        createTSANetCaseNote(caseRecordId, json)
        .then(response => {
            console.log('response : ', response)
            this.isLoading = false
            if(response){
                toast(this, 'Success', 'success', 'The Note have been created successfully!')
                this.handleCloseWindow(true)
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
                            this.handleCloseWindow(true)
                        }
                    })
                })
            }
        })
    }
    
    handleChangeField(event){
        this.note[event.target.name] = event.target.value
    }

    handleChangePriority(event){
        this.priority = event.target.value
    }

    handleClose(){
        this.handleCloseWindow(false)
    }

    handleCloseWindow(isRefresh){
        console.log('isRefresh: ', isRefresh)
        if(!this.isQuickAction){
            console.log('isRefresh: ', isRefresh)
            this.dispatchEvent(new CustomEvent('close', {
                detail: {
                    refresh: isRefresh
                }
            }))
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