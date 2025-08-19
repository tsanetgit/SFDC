import { LightningElement, api } from 'lwc'
import { NavigationMixin } from "lightning/navigation"
import { rejectRequest, getRelatedTSANetCases, toast } from 'c/tsaNetHelper'
 
export default class RejectIncomingRequest extends NavigationMixin(LightningElement) {

    @api recordId
    @api record
    @api caseRecord
    @api config
    @api currentUser

    @api isQuickAction = false

    isLoading = false
    isDone = false

    reason = ''

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
        this.reason = ''
    }

    handleChangeNote(event){
        this.reason = event.target.value
    }

    validate(data){
        if(data?.engineerName &&
            //data?.engineerEmail && 
            //data?.engineerPhone &&
            this.reason
        ){ return true } 
        else { return false }
    }

    handleReject(){

        let requestData = this.getRequestData()
        this.validateRequestData(requestData)

        console.log('REJECT REQUEST DATA:', JSON.stringify(requestData))

        this.isLoading = true
        rejectRequest(this.record?.Id, JSON.stringify(requestData)).then(response => {
            console.log('RESPONSE : ', response)

            this.isDone = true
            toast(this, 'Success', 'success', 'The case have been rejected successfully!')

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
            "reason": this.reason 
        }

        if(this.caseRecord && this.caseRecord?.Owner){
            requestData["engineerName"] = this.caseRecord?.Owner?.Name
            requestData["engineerEmail"] = this.caseRecord?.Owner?.Email
            requestData["engineerPhone"] = this.caseRecord?.Owner?.Phone
        } else {
            requestData["engineerName"] = this.currentUser.Name
            requestData["engineerEmail"] = this.currentUser.Email
            requestData["engineerPhone"] = this.currentUser.Phone
        }
        
        return requestData;
    }

    validateRequestData(requestData){
        if(!this.validate(requestData)){
            toast(this, 'Warning', 'warning', 'Please check if all the data has been filled out correctly!')
            return;
        }  
    }
}