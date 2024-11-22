({
	init : function(cmp, event, helper) {
		console.log('recordId: ',  cmp.get('v.recordId'))
        cmp.set('v.isLoading', true)
        helper.fetch(cmp, 'c.closeTSANetCase', { tsaNetCaseId: cmp.get('v.recordId') }).then(result => {
            console.log('result : ', result)
            cmp.set('v.isLoading', false)
            try {
            	let record = JSON.parse(result)
                if(record.hasOwnProperty('status') && record.status == 'CLOSED'){
                	helper.toast('Success', 'success', 'Case has been closed successfully!')
                }            	
            	helper.navigateToRecord(cmp, event, helper)
            } catch(e){
                helper.toast('Error', 'error', result)
            	helper.navigateToRecord(cmp, event, helper)
            }
        }).catch(error => {
            	if(error == 'Unauthorized'){
                    helper.fetch(cmp, 'c.getNewAccessToken', null).then(result => {
                        if(response){
                            helper.fetch(cmp, 'c.closeTSANetCase', { tsaNetCaseId: cmp.get('v.recordId') }).then(result => {
                                console.log('result : ', result)
                                cmp.set('v.isLoading', false)
                                try {
                                    let record = JSON.parse(result)
                                    if(record.hasOwnProperty('status') && record.status == 'CLOSED'){
                                        helper.toast('Success', 'success', 'Case has been closed successfully!')
                                    }            	
                                    helper.navigateToRecord(cmp, event, helper)
                                } catch(e){
                                    helper.toast('Error', 'error', result)
                                    helper.navigateToRecord(cmp, event, helper)
                                }
                            })
                        } else {
                            console.log(error)
                            helper.toast('Error', 'error', error)
                        }
                    }).catch(err => {
                        console.log(err)
                        helper.toast('Error', 'error', err)
                    })
                } else {
                    console.log(error)
                    helper.toast('Error', 'error', error)
                }
        })
	}
})