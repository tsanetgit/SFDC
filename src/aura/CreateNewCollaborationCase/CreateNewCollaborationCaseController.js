({

	init : function(cmp, event, helper) {
        console.log('1 ', cmp.get('v.recordId'))
        helper.fetch(cmp, 'c.getCaseInformation', { caseId: cmp.get('v.recordId') }).then(data => {
            console.log('response : ', data)
            cmp.set('v.currentState', data)
        }).catch(error => {
            console.log('error: ', error)
            if(error == 'Unauthorized'){
                helper.fetch(cmp, 'c.getNewAccessToken', undefined).then(response => {
                    console.log('token response : ', response)
                    helper.fetch(cmp, 'c.getCaseInformation', { caseId: cmp.get('v.recordId') })
                    .then(data => cmp.set('v.currentState', data))
                    .catch(error => { 
                         helper.toast('Error', 'error', error)
                    })
                })
                .catch(error => helper.toast('Error', 'error', error))
                return
            }
        })
            
	},
            
    close : function(cmp, event){
        $A.get("e.force:navigateToSObject").setParams({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'tsanet_connect__TSANetCase__c',
                actionName: 'list'
            },
            state: {       
                filterName: 'tsanet_connect__TSANetCaseView' 
            }
        }).fire();
    }        
            
})