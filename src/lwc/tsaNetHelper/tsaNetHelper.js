import { ShowToastEvent } from 'lightning/platformShowToastEvent'

import getCaseInformation from '@salesforce/apex/TSANetUtils.getCaseInformation'
import getCompaniesByName from '@salesforce/apex/TSANetService.getCompaniesByName'

import createCollaborationCase from '@salesforce/apex/TSANetService.createCollaborationCase'
import getAccessToken from '@salesforce/apex/TSANetService.getAccessToken'

import approveIncomingRequest from '@salesforce/apex/TSANetService.approveIncomingRequest'

import getFormByCompanyId from '@salesforce/apex/TSANetService.getFormByCompanyId'

import getTSANetCases from '@salesforce/apex/TSANetUtils.getTSANetCases'

import createCaseNote from '@salesforce/apex/TSANetService.createCaseNote'

import getSFCaseInformation from '@salesforce/apex/TSANetUtils.getSFCaseInformation'

export const TYPING_INTERVAL = 300

export const PRIORITIES = [
    { label: 'Low', value: 'low' },
    { label: 'Medium', value: 'medium' },
    { label: 'High', value: 'high' },
]

export const REQUIRED_FIELDS_WARNING = 'Please fill out all required fields!'

export const getNewAccessToken = () => {
    return new Promise((resolve, reject) => {
        getAccessToken()
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const getRelatedTSANetCases = (caseId) => {
    return new Promise((resolve, reject) => {
        getTSANetCases({ caseId })
            .then(response => resolve(response))
            .catch(error => reject(error))
    })
}

export const getCaseInfo = (caseId) => {
    return new Promise((resolve, reject) => {
        getCaseInformation({ caseId })
        .then(data => resolve(prepareCaseData(data)))
        .catch(error => reject(error))
    })
}

const prepareCaseData = (data) => {
    console.log('data', data)
    data.caseRecord['link'] = '/' + data.caseRecord.Id

    data?.relatedCases?.forEach(relatedCase => {
        relatedCase['link'] = '/' + relatedCase.Id
        relatedCase['caseLink'] = '/' + relatedCase.tsanet_connect__Case__c
        relatedCase['actionCss'] = relatedCase?.tsanet_connect__Status__c == 'ACCEPTED' || relatedCase?.tsanet_connect__Type__c == 'Outbound' ? 'slds-hide' : ''
        relatedCase['internalCaseNumber'] = '/' + relatedCase.Id

        relatedCase.isNoteable = ( relatedCase.tsanet_connect__Status__c == 'ACCEPTED' || relatedCase.tsanet_connect__Status__c == 'INFORMATION' )

        if(relatedCase?.tsanet_connect__TSANetResponses__r && relatedCase?.tsanet_connect__TSANetResponses__r.length){
            relatedCase['agentEmail'] = relatedCase?.tsanet_connect__TSANetResponses__r[0]?.tsanet_connect__EngineerEmail__c
        }
    })

    return data
}

export const getCompanies = (companyName, currentCompanyId) => {
    console.log('companyName : ', companyName)
    console.log('currentCompanyId : ', currentCompanyId)
    return new Promise((resolve, reject) => {
        getCompaniesByName({ companyName })
        .then(json => resolve(prepareCompaniesData(json, currentCompanyId)))
        .catch(error => reject(error))
    })
}

const prepareCompaniesData = (json, currentCompanyId) => {
    let companies = json && JSON.parse(json)
    console.log('companies: ', companies)
    return companies.filter(c => ( c.companyId != currentCompanyId))
}

export const createNewCollaborationCase = (caseId, json) => {
    return new Promise((resolve, reject) => {
        createCollaborationCase({ caseId, json })
        .then(response => {
            console.log('response ', response)
            resolve(response)
        }).catch(error => reject(error))
    })
}

export const approveRequest = (token, json) => {
    return new Promise((resolve, reject) => {
        approveIncomingRequest({ token, json})
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const getCompanyForm = (companyId, mode) => {
    return new Promise((resolve, reject) => {
        getFormByCompanyId({ companyId, mode })
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const createTSANetCaseNote = (caseId, json) => {
    return new Promise((resolve, reject) => {
        createCaseNote({ caseId, json })
        .then(response => resolve(response))
        .catch(error => reject(error))
    })
}

export const getSFTSANetCases = (caseId) => {
    return new Promise((resolve, reject) => {
        getSFCaseInformation({ caseId })
        .then(response => resolve(prepareCaseData(response)))
        .catch(error => reject(error))
    })
}

export const toast = (self, title, variant, message) => {
    self.dispatchEvent(new ShowToastEvent({ title: title, variant: variant, message: message }))
}

export const deepCopy = (value) => {
    return JSON.parse(JSON.stringify(value))
}