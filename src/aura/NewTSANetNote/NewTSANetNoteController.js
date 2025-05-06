({

	init : function(cmp, event, helper) {
        console.log(window.location.search)
        console.log('1 ', cmp.get('v.recordId'))
        
        const urlParams = new URLSearchParams(window.location.search);
        let recordId = urlParams.get('tsanet_connect__recordId');
        console.log('1 ', recordId)
        
        if(!recordId){
            recordId = urlParams.get('force__recordId')
        }
        console.log('2 ', recordId)
        
        cmp.set('v.recordId', recordId)
        
        helper.fetch(cmp, 'c.getOneTSANetCase', { caseId: recordId }).then(caseRecord => {
            cmp.set('v.externalCaseId', caseRecord.tsanet_connect__tsaNetCaseId__c)
        })
        
                
	},
            
    close : function(cmp, event){
        history.back()
        /*$A.get("e.force:navigateToSObject").setParams({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'tsanet_connect__TSANetNote__c',
                actionName: 'list'
            },
            state: {       
                filterName: '' 
            }
        }).fire();
        
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();*/
    }        
            
})