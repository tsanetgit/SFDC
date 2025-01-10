import { LightningElement, api, track } from 'lwc'

import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getTSANetRecordPageInfo from '@salesforce/apex/TSANetUtils.getTSANetRecordPageInfo'

import NAME_FIELD from '@salesforce/schema/TSANetCase__c.Name'
import CASE_FIELD from '@salesforce/schema/TSANetCase__c.Case__c'
import PRIORITY_NOTE_FIELD from '@salesforce/schema/TSANetCase__c.PriorityNote__c'
import TYPE_FIELD from '@salesforce/schema/TSANetCase__c.Type__c'
import SUMMARY_FIELD from '@salesforce/schema/TSANetCase__c.Summary__c'
import DESCRIPTION_FIELD from '@salesforce/schema/TSANetCase__c.Description__c'

import EXTERNAL_CASE_ID_FIELD from '@salesforce/schema/TSANetCase__c.tsaNetCaseId__c'
import STATUS_FIELD from '@salesforce/schema/TSANetCase__c.Status__c'
import PRIORITY_FIELD from '@salesforce/schema/TSANetCase__c.Priority__c'
import REQUEST_DATE_FIELD from '@salesforce/schema/TSANetCase__c.RequestDate__c'
import RESPONSE_DATE_FIELD from '@salesforce/schema/TSANetCase__c.ResponseDate__c'
import ESCALATION_INSTRUCTIONS_FIELD from '@salesforce/schema/TSANetCase__c.EscalationInstructions__c'
import ADMIN_NOTE_FIELD from '@salesforce/schema/TSANetCase__c.AdminNote__c'



import SUBMITTED_COMPANY_NAME_FIELD from '@salesforce/schema/TSANetCase__c.SubmittedCompanyName__c'
import OWNER_NAME_FIELD from '@salesforce/schema/TSANetCase__c.Name__c'
import EMAIL_FIELD from '@salesforce/schema/TSANetCase__c.Email__c'
import PHONE_FIELD from '@salesforce/schema/TSANetCase__c.Phone__c'
import CREATED_BY_FIELD from '@salesforce/schema/TSANetCase__c.CreatedById'

import RECEIVED_COMPANY_NAME_FIELD from '@salesforce/schema/TSANetCase__c.receivedCompanyName__c'
import ENGINEER_NAME_FIELD from '@salesforce/schema/TSANetCase__c.EngineerName__c'
import ENGINEER_EMAIL_FIELD from '@salesforce/schema/TSANetCase__c.EngineerEmail__c'
import ENGINEER_PHONE_FIELD from '@salesforce/schema/TSANetCase__c.EngineerPhone__c'
import LAST_MODIFIED_BY_FIELD from '@salesforce/schema/TSANetCase__c.LastModifiedById'

import TOKEN_FIELD from '@salesforce/schema/TSANetCase__c.Token__c'

import updateTSANetCase from '@salesforce/apex/TSANetUtils.updateTSANetCase'


export default class TsaNetRecordPage extends LightningElement {
    nameField = NAME_FIELD
    @track caseField = CASE_FIELD
    priorityNoteField = PRIORITY_NOTE_FIELD
    typeField = TYPE_FIELD
    summaryField = SUMMARY_FIELD
    descriptionField = DESCRIPTION_FIELD
    
    externalCaseId = EXTERNAL_CASE_ID_FIELD
    statusField = STATUS_FIELD
    priorityField = PRIORITY_FIELD 
    requestDateField = REQUEST_DATE_FIELD
    responseDateField = RESPONSE_DATE_FIELD
    escalationInstructionsField = ESCALATION_INSTRUCTIONS_FIELD
    adminNoteField = ADMIN_NOTE_FIELD

    submittedCompanyNameField = SUBMITTED_COMPANY_NAME_FIELD
    ownerNameField = OWNER_NAME_FIELD
    emailField = EMAIL_FIELD
    phoneField = PHONE_FIELD
    createdByField = CREATED_BY_FIELD

    receivedCompanyName = RECEIVED_COMPANY_NAME_FIELD
    engineerName = ENGINEER_NAME_FIELD
    engineerEmail = ENGINEER_EMAIL_FIELD
    engineerPhone = ENGINEER_PHONE_FIELD
    lastModifiedBy = LAST_MODIFIED_BY_FIELD
    tokenField = TOKEN_FIELD

    skipCustomFields = []

    @api recordId
    @api objectApiName = 'TSANetCase__c'

    isLoading = false
    isCaseMode = false

    caseRecord

    customFields = []

    connectedCallback(){
        this.getData()
    }

    getData(){
        getTSANetRecordPageInfo({ caseId: this.recordId }).then(record => {
            console.log('record!!!', record)

            this.caseRecord = record?.tsanet_connect__Case__r

            let customFields = [];

            if(record.tsanet_connect__customFields__c){
                let fields = JSON.parse(record.tsanet_connect__customFields__c)
                fields.forEach(field => {
                    if(!this.skipCustomFields.includes(field.fieldName)){
                        customFields.push(field);
                    }
                })
            }
            
            this.customFields.sort(function(a,b) {
                return a.displayOrder - b.displayOrder
            })

            this.customFields = customFields
        })
    }

    selectedCaseRecordId
    handleSelectNewCase(event){
        let selectedCaseRecord = event.detail
        console.log('selectedCaseRecord: ', selectedCaseRecord)
        this.selectedCaseRecordId = selectedCaseRecord
    }

    switchCaseMode(){
        console.log('work')
        this.isCaseMode = !this.isCaseMode
    }

    handleSubmit(){
        let tsanetCase = { Id: this.recordId , tsanet_connect__Case__c: this.selectedCaseRecordId }
        console.log('tsanetCase: ', JSON.stringify(tsanetCase))
        this.isLoading = true
        updateTSANetCase({ tsaNetCaseId: this.recordId, caseId: this.selectedCaseRecordId }).then(response => {
            console.log('updateTSANetCase : response : ', response)
            this.isLoading = false
            this.toast('Success', 'success', 'The record have been assigned successfully!')
            this.isCaseMode = false
            this.getData()
            getRecordNotifyChange([{recordId: this.recordId}]);
        }).catch(error => {
            this.toast('Error', 'error', error.body.message)
        })
    }
    /*

    handleSubmit(event){
        this.isLoading = true
        event.preventDefault()
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(){
        this.isLoading = false
        this.toast('Success', 'success', 'The record have been assigned successfully!')
        this.isCaseMode = false
    }
    */
    toast(title, variant, message){
        this.dispatchEvent(new ShowToastEvent({ title: title, variant: variant, message: message }))
    }
}