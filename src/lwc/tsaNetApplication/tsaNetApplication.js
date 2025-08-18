import { LightningElement, track, api } from 'lwc'
import TSANetLogo from '@salesforce/resourceUrl/TSANetLogo'
import { getNewAccessToken, getCaseInfo, toast } from 'c/tsaNetHelper'
 
export default class TsaNetApplication extends LightningElement {
    @api recordId

    @track state = {}

    isLogin = false
    isLoading = false
    isUnauthorized = false
    relatedCases = []

    connectedCallback(){
        console.log('recordId : ', this.recordId)
        this.getData()
    }

    getData(){
        this.isLoading = true
        getCaseInfo(this.recordId)
        .then(data => this.setData(data))
        .then(() => this.isLoading = false)
        .catch(error => { 
            
            console.log('error : ', error)
            console.log('error?.body?.message : ', error?.body?.message)

            if(error?.body?.message == 'Unauthorized'){
                getNewAccessToken()
                .then(response => {
                    console.log('token response : ', response)
                    if(response){
                        getCaseInfo(this.recordId)
                        .then(data => this.setData(data))
                        .catch(error => { 
                            console.error('error : ', error)
                        })
                        .finally(() => this.isLoading = false)
                    } else {
                        this.isLoading = false
                        this.isLogin = true
                        toast(this, 'Unauthorized!', 'warning', 'Please check your username and password!')
                        console.error('response : ', response)
                    }
                })
                .catch(error => { 
                    toast(this, 'Error', 'error', error?.body?.message)
                })
                .finally(() => this.isLoading = false)
                return
            } else if(error?.body?.message == 'Username and password can not be empty!'){
                this.isLoading = false
                this.isLogin = true

                toast(this, 'Warning!', 'warning', error?.body?.message)
                return
            } else {
                //this.isLoading = false
            }
        })
    }

    setData(data){
        data['logo'] = TSANetLogo
        this.state = data
        this.relatedCases = data.relatedCases 
    }

    handleRefresh(){
        this.isLogin = false
        this.isLoading = false
        this.getData()
    }
}