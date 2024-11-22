({
	init : function(cmp, event, helper) {
        let caseId = cmp.get('v.recordId');
        console.log('caseId: ', caseId)
        helper.fetch(cmp, 'c.refreshOnCase', { caseId }).then(response => {
            console.log('response : refresh : cases : ', response)
        	$A.get('e.force:refreshView').fire();
        	helper.navigateToRecord(cmp, event, helper)
        }).catch(error => {
            console.log('catch')
        	$A.get('e.force:refreshView').fire()
            helper.navigateToRecord(cmp, event, helper)
        })
	}
})