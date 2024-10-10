import { LightningElement, api, track } from 'lwc'
import { NavigationMixin } from "lightning/navigation"

import TSANetLogo from '@salesforce/resourceUrl/TSANetLogo'

import { getRelatedTSANetCases } from 'c/tsaNetHelper'

import './relatedList.css'
 
export default class RelatedList extends NavigationMixin(LightningElement) {

    @api recordId
    @api isLogin

    isLoading

    isNew = false
    isApprove = false

    isNoteMode = false
    externalCaseId 

    logo = TSANetLogo
    @track columns
    @track record
    @track records = []
    unAssignedCases = []
    @track caseRecord
    @track config 

    @track _state

    @api
    get state(){
        return this._state
    }

    set state(value){

        this._state = value

        this.config = value?.config
        this.records = value?.relatedCases ? value.relatedCases : []
        this.caseRecord = value?.caseRecord
        this.columns = value?.columns
        //this.logo = value?.logo
    }

    handleGotoRelatedList() {
        this[NavigationMixin.Navigate]({
            type: "standard__recordRelationshipPage",
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Case',
                relationshipApiName: 'TSANetCases__r',
                actionName: 'view'
            }
        })
    }

    handleRefresh(){
        this.isLoading = true
        getRelatedTSANetCases(undefined).then(response => {
            this.dispatchEvent(new CustomEvent('refresh'))
        }).finally(() => {
            this.isLoading = false
        })
    }

    handleSwitchNew(){
        this.isNew = !this.isNew
    }

    handleSwitchApprove(){
        this.isApprove = !this.isApprove
    }

    handleOnNote(event){
        this.isNoteMode = true
    }

    handleOnCloseNote(event){
        this.isNoteMode = false
    }

    addNewNote(event){
        let externalId = event.currentTarget.dataset.id
        this.externalCaseId = externalId

        this.isNoteMode = true
        this.dispatchEvent(new CustomEvent('opennote'), {
            detail: this.isNoteMode
        })
    }

    handleCloseNoteNode(){
        this.isNoteMode = false
        this.dispatchEvent(new CustomEvent('closenote'), {
            detail: this.isNoteMode
        })
    }

    get recordsLength(){ return this.records && this.records?.length ? this.records.length : '0' }

    get datatableHeight() {
        if(this.records?.length == 0){
            return 'min-height:3rem;';
        } else if(this.records?.length > 3){
            return 'min-height:300px;';
        } else {
            return 'min-height:150px;'
        }
    }

    get title(){
        return ' TSANet Cases (' + this.recordsLength + ')'
    }


        /*
    selectedRecord 
    show = false
    showTable = false
    activeRecordsCount = 0
    left
    top

    handlePopoverLeave(event){
        console.log('leave')
        this.showTable = false
        this.show = false
        this.selectedRecord = undefined
        
    }

    handlePopover(event){

        console.log('handlePopover')

        if(this.isNoteMode || this.showTable){ 
            return 
        }

        this.showTable = !this.showTable

        console.log(this.showTable)

        if(this.showTable){

            this.show = true
            this.left = event.clientX;
            this.top= event.clientY;

            console.log('record?.weeks : ')

            let selectedRecordId = event.currentTarget.dataset.recordid
            let selectedRecord = this.records.find(record => (record.Id == selectedRecordId))
            this.selectedRecord = selectedRecord
            console.log("JSON> ", JSON.stringify(selectedRecord))
        } else {
            this.show = false;
            this.selectedRecord = undefined
        }

    }

    handleClose() {
        this.show = false;
        this.showTable = !this.showTable
        this.selectedRecord = undefined
    }


    handleOnShowDetail(event){

        this.showTable = !this.showTable

        console.log(this.showTable)

        if(this.showTable){

            this.show = true
            this.left = event.clientX;
            this.top= event.clientY;

            console.log('record?.weeks : ')

            let selectedRecordId = event.currentTarget.dataset.recordid
            this.selectedRecord = this.records.find(record => (record.Id == selectedRecordId))
            this.selectedRecord = selectedRecord
            console.log("JSON> ", JSON.stringify(selectedRecord))
        } else {
            this.show = false;
            this.selectedRecord = undefined
        }
    }

    handleOnHideDetail(event){
        this.showTable = !this.showTable

        console.log(this.showTable)

        if(this.showTable){

            this.show = true
            this.left = event.clientX;
            this.top= event.clientY;

            console.log('record?.weeks : ')

            let selectedRecordId = event.currentTarget.dataset.recordid
            this.selectedRecord = this.records.find(record => (record.Id == selectedRecordId))
            this.selectedRecord = selectedRecord
            console.log("JSON> ", JSON.stringify(selectedRecord))
        } else {
            this.show = false;
            this.selectedRecord = undefined
        }
    }

    handleMouseover(event){
        console.log(1)
        this.dispatchEvent(new CustomEvent('showdetail'), { detail: event })
    }

    handleMouseout(event){
        console.log(2)
        this.dispatchEvent(new CustomEvent('hidedetail'), { detail: event })
    }

    */

}