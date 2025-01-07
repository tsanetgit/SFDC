import { LightningElement, api } from 'lwc'
import { NavigationMixin } from "lightning/navigation"
import { requestAdditionalInfo, getNewAccessToken, getRelatedTSANetCases, toast } from 'c/tsaNetHelper'
 
 
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

    validate(data){
        if(data?.engineerName &&
            //data?.engineerEmail && 
            //data?.engineerPhone &&
            this.additionalInfo
        ){ return true } 
        else { return false }
    }

    handleRequestAdditionalInfo(){

        let requestData = {
            "requestedInformation": this.additionalInfo 
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

        if(!this.validate(requestData)){
            toast(this, 'Warning', 'warning', 'Please check if all the data has been filled out correctly!')
            return;
        }       

        console.log('requestData :', JSON.stringify(requestData))

        this.isLoading = true

        requestAdditionalInfo(this.record?.Id, JSON.stringify(requestData)).then(response => {
            console.log(response)

            this.isDone = true
            toast(this, 'Success', 'success', 'Additional Information has been requested successfully!')

            this.handleCloseWindow(true)

        }).catch(error => {
            if(error?.body?.message == 'Unauthorized'){
                getNewAccessToken().then(response => {
                    if(response){
                        requestAdditionalInfo(this.record?.Id, JSON.stringify(requestData)).then(response => {
                            console.log(response)
                
                            this.isDone = true
                            toast(this, 'Success', 'success', 'Additional Information has been requested successfully!')
                
                            this.handleCloseWindow(true)
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