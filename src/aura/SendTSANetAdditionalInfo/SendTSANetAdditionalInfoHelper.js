({
	fetch : function(cmp, method, params) {
        return new Promise($A.getCallback(function(resolve, reject) {
            cmp.set('v.isLoading', true)
            const action = cmp.get(method)
            params && action.setParams(params)
            action.setCallback(this, response => {
                cmp.set('v.isLoading', false)
                const state = response.getState()
                switch (state) {
                case 'SUCCESS': resolve(response.getReturnValue())
                break
                case 'INCOMPLETE': console.log('INCOMPLETE')
                break
                case 'ERROR': const errors = response.getError()
                errors 
                ? reject(errors[0].message)
                : console.log('Unknown error')
                break
                default: console.log(state)
            }
                               })
            $A.enqueueAction(action)
        }))
    },
    
    navigateToRecord: function(cmp, event, helper) {
        let navService = cmp.find("navService");
        if(navService){
            let pageReference = {
                type: 'standard__recordPage',
                attributes: {
                    recordId: cmp.get("v.recordId"),
                    objectApiName: "tsanet_connect__TSANetCase__c",
                    actionName: "view"
                }
            }
            navService.navigate(pageReference)
            
            $A.get('e.force:refreshView').fire()
        }
    },
    
    toast : function(title, type, message) {
        $A.get("e.force:showToast").setParams({ title: title, type: type, message: message }).fire()
    }
})