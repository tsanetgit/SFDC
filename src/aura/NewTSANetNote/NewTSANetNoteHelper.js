({
    
    decodeInContextOfRef : function(cmp, inContextOfRef) {
        // Отримуємо сервіс навігації
        var navService = cmp.find("navService");

        // Використовуємо Navigation API для декодування inContextOfRef
        var pageReference = {
            type: "standard__recordPage",
            attributes: {
                recordId: inContextOfRef,
                actionName: "view"
            }
        };

        // Генеруємо URL, щоб отримати розшифрований recordId
        navService.generateUrl(pageReference)
        .then(function(url) {
            console.log("Decoded URL: " + url);
            // Ти можеш дістати recordId з цього URL, якщо це потрібно
            // Наприклад, витягаємо recordId з URL
            var recordIdMatch = url.match(/\/([a-zA-Z0-9]{18})/);
            if (recordIdMatch) {
                var recordId = recordIdMatch[1];
                cmp.set("v.recordId", recordId);
            }
        })
        .catch(function(error) {
            console.error("Error decoding inContextOfRef:", error);
        });
    },
    
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
    toast : function(title, type, message) {
        $A.get("e.force:showToast").setParams({ title: title, type: type, message: message }).fire()
    }
})