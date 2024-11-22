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
        if(data.requestedInformation
        ){ return true } 
        else { return false }
    }

    handleSendAdditionalInfo(){

        let requestData = {
            "requestedInformation": this.additionalInfo 
        }

        if(!this.validate(requestData)){
            toast(this, 'Warning', 'warning', 'Please check if all the data has been filled out correctly!')
            return;
        }       

        console.log('requestData :', JSON.stringify(requestData))

        this.isLoading = true

        sendAdditionalInfo(this.record?.Id, JSON.stringify(requestData)).then(response => {
            console.log(response)

            this.isDone = true
            toast(this, 'Success', 'success', 'Additional Information has been sent!')

            this.handleCloseWindow(true)

        }).catch(error => {
            if(error?.body?.message == 'Unauthorized'){
                getNewAccessToken().then(response => {
                    if(response){
                        sendAdditionalInfo(this.record?.Id, JSON.stringify(requestData)).then(response => {
                            console.log(response)
                
                            this.isDone = true
                            toast(this, 'Success', 'success', 'Additional Information has been sent!')
                
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