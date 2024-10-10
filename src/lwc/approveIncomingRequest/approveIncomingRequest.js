import { LightningElement, api } from 'lwc'
import { NavigationMixin } from "lightning/navigation"
import { approveRequest, getNewAccessToken, getRelatedTSANetCases, toast } from 'c/tsaNetHelper'
 
export default class ApproveIncomingRequest extends NavigationMixin(LightningElement) {

    @api recordId
    @api record
    @api caseRecord
    @api config

    @api isQuickAction = false

    isLoading = false
    isDone = false

    note = 'Our assigned engineer will contact you.'

    handleClose(){
        this.clearState()
        if(!this.isQuickAction){
            this.dispatchEvent(new CustomEvent('close'))
        } else {
            this[NavigationMixin.Navigate]({    
                type: "standard__recordPage",
                attributes: {
                    recordId: this.recordId,
                    actionName: "view"
                }
            })
            location.reload()
        }
    }

    clearState(){
        this.record = undefined
        this.caseRecord  = undefined
        this.isLoading = false
        this.isDone = false
        this.note = 'Our assigned engineer will contact you.'
    }

    handleChangeNote(event){
        this.note = event.target.value
    }

    handleApprove(){

        let requestData = {
            "caseNumber": this.record?.tsanet_connect__tsaNetCaseId__c,
            "engineerName": this.caseRecord.Owner.Name,
            "engineerEmail": this.config?.tsanet_connect__Username__c,
            "engineerPhone": this.caseRecord.Owner.Phone,
            "nextSteps": this.note
        }

        console.log('requestData :', JSON.stringify(requestData))

        this.isLoading = true

        approveRequest(this.record?.tsanet_connect__Token__c, JSON.stringify(requestData)).then(response => {
            console.log(response)

            this.isDone = true
            toast(this, 'Success', 'success', 'The case have been submitted successfully!')

            this.dispatchEvent(new CustomEvent('close'))

        }).catch(error => {
            if(error?.body?.message == 'Unauthorized'){
                getNewAccessToken().then(response => {
                    if(response){
                        approveRequest(this.record?.tsanet_connect__Token__c, JSON.stringify(requestData)).then(response => {
                            console.log(response)
                
                            this.isDone = true
                            toast(this, 'Success', 'success', 'The case have been submitted successfully!')
                
                            this.dispatchEvent(new CustomEvent('close'))
                        })
                    } else {
                        console.log(error)
                        toast(this, 'Error', 'error', error?.body?.message)
                    }
                }).catch(err => {
                    console.log(err)
                    toast(this, 'Error', 'error', err?.body?.message)
                })
            } else {
                console.log(error)
                toast(this, 'Error', 'error', error?.body?.message)
            }
            

            

            getRelatedTSANetCases(undefined)

        })
        .catch(error => toast(this, 'Error', 'error', error?.body?.message))
        .finally(() => this.isLoading = false)

    }
}