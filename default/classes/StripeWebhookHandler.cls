@RestResource(urlMapping='/stripe/webhook/*')
global without sharing class StripeWebhookHandler {
    @HttpPost
    global static void handleEvent() {
        system.debug('webhook event called');
        RestRequest req = RestContext.request;
        String payload = req.requestBody.toString();
		system.debug('payload--'+payload);
        system.debug('header---'+req.headers.keySet());
        
        // CRITICAL: verify the Stripe-Signature header before trusting anything
        
        String stripeSignature = null;
        
        // Loop through keys case-insensitively to guarantee extraction
        for (String headerName : req.headers.keySet()) {
            if (headerName.equalsIgnoreCase('Stripe-Signature')) {
                stripeSignature = req.headers.get(headerName);
                system.debug('stripeSignature---'+stripeSignature);
                system.debug('stripe--'+headerName.equalsIgnoreCase('Stripe-Signature'));
                break;
            }
        }
		if (!StripeSignatureVerifier.isValid(
                payload,
                stripeSignature)) {
            RestContext.response.statusCode = 400;
            return;
        } 

        Map<String, Object> event =
            (Map<String, Object>) JSON.deserializeUntyped(payload);

        if (event.get('type') == 'payment_intent.succeeded') {
            Map<String, Object> obj =
                (Map<String, Object>)((Map<String, Object>) event.get('data')).get('object');
            String intentId = (String) obj.get('id');

          /*  Payment__c p = [SELECT Id, Status__c FROM Payment__c
                            WHERE Stripe_PaymentIntent_Id__c = :intentId LIMIT 1];
            p.Status__c = 'Paid';
            update p;*/
        }
        RestContext.response.statusCode = 200; // ack so Stripe stops retrying
    }
}
