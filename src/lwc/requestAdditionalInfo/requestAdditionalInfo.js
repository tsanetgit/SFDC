import { LightningElement, api } from 'lwc'
import { NavigationMixin } from "lightning/navigation"
import { requestAdditionalInfo, getRelatedTSANetCases, toast } from 'c/tsaNetHelper'
 
export default class RequestAdditionalInfo extends NavigationMixin(LightningElement) {

    @api recordId
    @api record
    @api caseRecord
    @api config
    @api currentUser

    @api isQuickAction = false

    isLoading = false
    isDone = false

    additionalInfo = ''

    handleClose(isRefresh){
        console.log('isRefresh: ', isRefresh)
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

    handleRequestAdditionalInfo(){

        let requestData = this.getRequestData()
        this.validateRequestData(requestData)

        console.log('REJECT REQUEST DATA:', JSON.stringify(requestData))

        this.isLoading = true
        requestAdditionalInfo(this.record?.Id, JSON.stringify(requestData)).then(response => {
            console.log('RESPONSE : ', response)
            this.isDone = true
            toast(this, 'Success', 'success', 'Additional Information has been requested successfully!')
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
        .catch(error => toast(this, 'Error', 'error', error?.body?.message))
        .finally(() => this.isLoading = false)
    }

    getRequestData(){

        let requestData = {
            "requestedInformation": this.additionalInfo 
        }

        if(this.caseRecord && this.caseRecord?.Owner){
            requestData["engineerName"] = this.caseRecord?.Owner?.Name
            requestData["engineerEmail"] =  this.caseRecord?.Owner?.Email
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

    validate(data){
        if(data?.engineerName &&
            //data?.engineerEmail && 
            //data?.engineerPhone &&
            this.additionalInfo
        ){ return true } 
        else { return false }
    }
}