({
	init : function(cmp, event, helper) {
        console.log('recordId: ',  cmp.get('v.recordId'))
        helper.fetch(cmp, 'c.getTSANetInfo', { recordId: cmp.get('v.recordId') }).then(data => {
            console.log('response : ', data)
            cmp.set('v.record', data.record)
            cmp.set('v.caseRecord', data.caseRecord)
            cmp.set('v.config', data.config)
            cmp.set('v.currentUser', data.currentUser)
        })
	},
            
    close : function(cmp, event, helper){
        $A.get('e.force:refreshView').fire();
 		//helper.navigateToRecord(cmp, event, helper)
    }    
})