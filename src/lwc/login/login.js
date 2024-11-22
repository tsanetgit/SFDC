import { LightningElement } from 'lwc';

import updateUserCredentials  from '@salesforce/apex/TSANetUtils.updateUserCredentials'
import updateCustomSettingsCredentials from '@salesforce/apex/TSANetService.updateCustomSettingsCredentials'
import TSANetLogo from '@salesforce/resourceUrl/TSANetLogo'

import { 
    getNewAccessToken, toast 
} from 'c/tsaNetHelper'
 
export default class Login extends LightningElement {

    logo = TSANetLogo
    username
    password

    handleChangeUserName(event){
        this.username = event.target.value
    }

    handleChangePassword(event){
        this.password = event.target.value
    }

    handleLogin(){
        
        console.log('this.username : ', this.username )
        console.log('this.password : ', this.password )

        updateUserCredentials({ username : this.username, password: this.password }).then(() => {
            getNewAccessToken()
            .then(response => {
                console.log('response :', response)
                response ? toast(this, 'Success!', 'success', 'You are successfully logged in!') : toast(this, 'Error!', 'error', 'Please check your credentials to TSANet Connect!')
                response && updateCustomSettingsCredentials()
                .then(() => this.handleRefresh())
                .catch(error =>  toast(this, 'Error!', 'error', error?.body?.message) )
            }).catch(error => toast(this, 'Error!', 'error', error?.body?.message))
        }).catch(error => toast(this, 'Error!', 'error', error?.body?.message))
    }

    handleRefresh(){
        this.dispatchEvent(new CustomEvent('refresh'))
    }
}