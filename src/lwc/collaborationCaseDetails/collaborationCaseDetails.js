import { LightningElement, api } from 'lwc';
 
export default class CollaborationCaseDetails extends LightningElement {
    isLoading = false
    objectApiName = 'TSANetCase__c'
    @api record

    handleClose(){
        this.dispatchEvent(new CustomEvent('close'))
    }
}