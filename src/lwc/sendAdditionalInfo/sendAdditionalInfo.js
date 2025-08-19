import { LightningElement, api } from 'lwc'
import { NavigationMixin } from "lightning/navigation"
import { sendAdditionalInfo, getNewAccessToken, getRelatedTSANetCases, toast } from 'c/tsaNetHelper'
 
export default class SendAdditionalInfo extends NavigationMixin(LightningElement) {

    @api recordId
    @api record
    @api caseRecord
    @api config
    @api currentUser

    @api isQuickAction = false

    isLoading = false
    isDone = false

    additionalInfo = ''

    handleClose(){
        this.handleCloseWindow(false)
    }

    handleCloseWindow(isRefresh){
        console.log('isRefresh: ', isRefresh)
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
        this.caseRecord  = undefined
        this.isLoading = false
        this.isDone = false
        this.additionalInfo = ''
    }

    handleChangeNote(event){
        this.additionalInfo = event.target.value
    }

    handleSendAdditionalInfo(){

        let requestData = this.getRequestData()
        this.validateRequestData(requestData)

        console.log('REJECT REQUEST DATA:', JSON.stringify(requestData))

        this.isLoading = true
        sendAdditionalInfo(this.record?.Id, JSON.stringify(requestData)).then(response => {
            console.log('RESPONSE : ', response)
            this.isDone = true
            toast(this, 'Success', 'success', 'Additional Information has been sent!')
            this.handleCloseWindow(true)
        }).catch(error => {
            let errorResponse = error?.body?.message
            console.log('ERROR : ', errorResponse)
            if(errorResponse){
                let err = JSON.parse(errorResponse)
                let errorMessage = err?.message
                toast(this, 'Error', 'error', errorMessage)
            }
            
            getRelatedTSANetCases(undefined)
        })
        .finally(() => this.isLoading = false)
    }

    getRequestData(){

         let requestData = {
            "requestedInformation": this.additionalInfo 
        }
        
        return requestData;
    }

    validateRequestData(requestData){
        if(!this.validate(requestData)){
            toast(this, 'Warning', 'warning', 'Please check if all the data has been filled out correctly!')
            return;
        }       
    }

    validate(data){
        if(data.requestedInformation
        ){ return true } 
        else { return false }
    }
}