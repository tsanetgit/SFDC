import { LightningElement, api, track } from 'lwc'
import { NavigationMixin } from "lightning/navigation"

import getCustomFields from '@salesforce/apex/TSANetService.getCustomFields'

import getTierPickListValues from '@salesforce/apex/TSANetService.getTierPickListValues'

import { 
    TYPING_INTERVAL, PRIORITIES, REQUIRED_FIELDS_WARNING,
    getCaseInfo, getNewAccessToken, getCompanies, createNewCollaborationCase, getCompanyForm, toast 
} from 'c/tsaNetHelper'
 
export default class PartnerCollaborationCaseForm extends NavigationMixin(LightningElement) {

    @api recordId
    @api isQuickAction = false

    caseRecord
    config

    searchText = ''

    isLoading = false
    company
    companies = []

    // Additional fields
    subject
    priority 
    priorities = PRIORITIES
    problemInformation
    parentCase = ''

    firstStep = true
    form 

    tierPicklistValues = new Map()

    isDone = false
    tsaResponse

    customFieldMap = new Map()

    skipCustomFields = ['Customer Company', 'Customer Name', 'Customer Email', 'Customer Phone Including Country Code']

    typingTimer

    _state

    @api
    get state(){
        return this._state
    }

    set state(value){

        console.log('value  : ', value)
        console.log('value  : ', JSON.stringify(value))

        this.config = value?.config
        this.caseRecord = value?.caseRecord
        this.subject = value?.caseRecord?.Subject
    }

    handleClose(){
        this.handleCloseWindow(this.isDone)
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
            if(this.recordId){
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Case',
                        actionName: 'view' 
                    }
                });
            } else {
                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'tsanet_connect__TSANetCase__c',
                        actionName: 'list'
                    },
                    state: {       
                        filterName: 'tsanet_connect__TSANetCaseView' 
                    }
                })
            }
        }
    }

    handleBack(){

        this.isDone && this.handleCloseWindow()

        if(!this.firstStep){
            this.firstStep = true
            return
        }

        this.handleCloseWindow(false)
    }

    handleSearchKey(event){
        clearTimeout(this.typingTimer)

        this.searchText = event.target.value

        if(event?.target?.value){
            this.typingTimer = setTimeout(() => {
                this.companies = []
                this.isLoading = true

                console.log('config?.companyId__c : ', this.config)
                console.log('config?.companyId__c : ', this.config?.companyId__c)

                getCompanies(this.searchText, this.config?.companyId__c)
                .then(companies => { 
                    this.companies = companies
                })
                .then(() => this.isLoading = false )
                .catch(error => {
                    if(error?.body?.message == 'Unauthorized'){
                        getNewAccessToken().then(response => {
                            console.log('token response : ', response)
                            getCompanies(this.searchText, this.config?.companyId__c)
                            .then(companies => this.companies = companies)
                            .catch(error => toast(this, 'Error', 'error', error?.body?.message))
                            .finally(() => this.isLoading = false)
                        })
                        return
                    }
                    toast(this, 'Error', 'error', error?.body?.message)
                })

            }, TYPING_INTERVAL)
        } else {
            this.companies = []
        }
    }

    @track customFields = []

    selectCompany(event){

        let departmentId = event?.currentTarget?.dataset?.department

        if(departmentId){
            this.company = this.companies.find(company => ( ( company.departmentId + '') == departmentId))
        } else{
            this.company = this.companies.find(company => ( ( company.companyId + '') == event?.currentTarget?.dataset?.value))
        }

        if(this.company){
            this.isLoading = true

            let recordId = this.company?.departmentId ? this.company?.departmentId : this.company?.companyId
            let mode = this.company?.departmentId ? 'department' : 'company'
            getCompanyForm(recordId, mode).then(form => {
                if(form == 'You are not able to interact with the referenced company.'){
                    toast(this, 'Warning', 'warning', form)
                    return 
                }
                this.form = form && JSON.parse(form)

                let customFields = []
                this.form?.customerData && this.form?.customerData.forEach(customField => {
                    getCustomFields({ documentId: this.form.documentId, fieldId: customField.id }).then(resp => {
                        let field = JSON.parse(resp)
                        if(!this.skipCustomFields.includes(field.label)){
                            //field['required'] = true // REMOVE 
                            field['isSelect'] = field?.type == 'SELECT'
                            field['isTierSelect'] = field?.type == 'TIERSELECT'
                            field['isString'] = field?.type == 'STRING'

                            if(field?.isSelect){
                                let options = field?.options.split('\r\n')
                                field['values'] = options.map(o => ({ label: o, value: o }))
                            }

                            if(field?.isTierSelect){
                                getTierPickListValues({ documentId: this.form.documentId, fieldId: customField.id }).then(options => {
                                    let values = options && JSON.parse(options)
                                    let mappedValues = values.map(o => ({ label: o.value, value: o.value, children: o.children }))
                                    field['values'] = mappedValues
                                    this.tierPicklistValues.set(field.label, undefined)
                                })
                            }
                            
                            customFields.push(field)
                        }
                        this.isLoading = false
                    })
                })

                this.customFields = customFields;
                this.isLoading = false

            }).catch(error => {
                console.error('error :', error)
            })
        } else {
            this.handleChangeCompany()
        }
    }

    handleOnSelectPicklist(event){
        let data = event.detail
        
        this.customFields.forEach(c => {
            if(c.label == data.label){
                c.value = data.value
            }
        })

        this.customFieldMap.set(data.label, data.value)
    }

    handleChangeSelect(event){
        let fieldName = event.target.label
        let value = event.target.value

        this.customFields.forEach(c => {
            if(c.label == fieldName){
                c.value = value
            }
        })

        this.customFieldMap.set(fieldName, value)
    }

    handleChangeCompany(){
        this.company = undefined
        this.companies = []
        this.searchText = ''
    }

    handleNext(){
        if(this.firstStep){
            if(this.caseRecord?.Id != undefined && !this.caseRecord?.Contact?.Name){
                toast(this, REQUIRED_FIELDS_WARNING, 'warning', 'The contact field cannot be null!')
                return;
            } else if(this.caseRecord?.Id != undefined && !this.caseRecord?.Account?.Name){
                toast(this, REQUIRED_FIELDS_WARNING, 'warning', 'The account field cannot be null!')
                return;
            }
            this.firstStep = false
            return 
        }

        this.handleSubmit()
    }

    handleSubmit(){

        if(!this.problemInformation || !this.priority){
            toast(this, 'Warning!', 'warning', REQUIRED_FIELDS_WARNING)
            return
        }

        let data = this.getCustomForm()

        if(data?.hasError){ return }

        let object = data?.object

        this.isLoading = true

        createNewCollaborationCase(this.recordId, JSON.stringify(object))
        .then(response => {
            console.log('response =>>> ', response)

            let res = JSON.parse(response)

            console.log('res : ', res)

            toast(this, 'Success', 'success', 'The case have been submitted successfully!')

            this.tsaResponse = res
            this.isDone = true

        }).catch(error => {
            console.error('error: ', error)
            toast(this, 'Error', 'error', error?.body?.message)
        }).finally(() => {
            this.isLoading = false
        })
    }

    getCustomForm(){
        let hasError = false
        let object = {}

        let skipFields= ['readonlyAdminNote', 'readonlyEscalationInstructions']
        for (const [key, value] of Object.entries(this.form)) {
            if(!skipFields.includes(key)){
                if(key == 'problemSummary'){
                    object[key] = this.subject
                } else if(key == 'problemDescription'){
                    object[key] = this.problemInformation
                } else if(key == 'casePriority'){
                    object[key] = this.priority
                } else if(key == 'internalCaseNumber'){
                    object[key] = this.caseRecord.CaseNumber
                } else if(key == 'optionalRecieverInternalCaseNumber'){
                    object[key] = this.parentCase
                } else if(key == 'customerData'){
                    let clonnedValue = JSON.parse(JSON.stringify(value))

                    clonnedValue.forEach(customField => {
                        if(customField.fieldName == 'Customer Company'){
                            customField.value = this.caseRecord.Account.Name
                        } else if(customField.fieldName == 'Customer Name') {
                            customField.value = this.caseRecord.Contact.Name
                        } else if(customField.fieldName == 'Customer Email'){
                            customField.value = this.caseRecord.Contact.Email
                        } else if(customField.fieldName == 'Customer Phone Including Country Code'){
                            customField.value = this.caseRecord.Contact.Phone ? this.caseRecord.Contact.Phone : ''
                        } else {
                            if(this.customFieldMap.has(customField.fieldName)){
                                customField.value = this.customFieldMap.get(customField.fieldName)
                            } else {
                                customField.value = ''
                            }
                        }

                        this.customFields.forEach(c => {
                            if(c.label == customField.fieldName 
                                && ( customField.value == '' || customField.value == undefined ) 
                                && c.required){
                                toast(this, 'Warning!', 'warning', REQUIRED_FIELDS_WARNING)
                                hasError = true
                            }
                        })
                        
                    })
                    object[key] = clonnedValue
                } else {
                    object[key] = value
                }
            }
        }

        console.log('CASE OBJECT : ', JSON.stringify(object))

        return { hasError, object } 
    }

    handleChangeCustomField(event){
        let fieldName = event.target.label
        let value = event.target.value

        this.customFields.forEach(c => {
            if(c.label == fieldName){
                c.value = value
            }
        })

        this.customFieldMap.set(fieldName, value)
        console.log(fieldName + 'customField Value : ', value);
    }

    handleProblemInformation(event){
        this.problemInformation = event.target.value
    }

    handleChangePriority(event){
        this.priority = event.target.value
    }

    handleChangeSubject(event){
        this.subject = event.target.value
    }

    handleRefresh(){
        this.dispatchEvent(new CustomEvent('refresh'))
    }

    handleChangeCase(event){

        console.log('event case ->> ', event.target.value)

        let recordId = event.target.value
        this.recordId = recordId

        getCaseInfo(recordId)
        .then(data => {
            this.config = data?.config

            console.log('data22: ', data)

            console.log('data22: ', data)

            if(!data?.caseRecord?.Contact?.Name){
                toast(this, REQUIRED_FIELDS_WARNING, 'warning', 'The contact field cannot be null!')
                this.firstStep = true
                this.caseRecord = undefined
                return;
            } else if(!data?.caseRecord?.Account?.Name){
                toast(this, REQUIRED_FIELDS_WARNING, 'warning', 'The account field cannot be null!')
                this.firstStep = true
                this.caseRecord = undefined
                return;
            } else {
                this.caseRecord = data?.caseRecord
                this.subject = data?.caseRecord?.Subject
            }
        })
        .then(() => this.isLoading = false)
        .catch(error => { 
            console.log('error', error)
        })

    }

    clearState(){
        this._state = undefined
        this.caseRecord = undefined
        this.config = undefined
        this.searchText = ''
        this.isLoading = false
        this.company = undefined
        this.companies = []
        this.subject = undefined
        this.priority = undefined
        this.priorities = PRIORITIES
        this.problemInformation = undefined
        this.parentCase = ''
        this.firstStep = true
        this.form = undefined
        this.typingTimer = undefined
    }

    get boxHeight(){
        return ( this.isLoading || this.companies.length ) ? 'height: 200px;' : ''
    }

    get buttonDisabled(){
        return !this.company || this.isLoading ? true : false
    }

    get cancelButtonLabel(){
        return this.firstStep ? 'Cancel': 'Back'
    }

    get submitButtonLabel(){
        return this.firstStep ? 'Next': 'Submit'
    }
}