@RestResource(urlMapping='/stripe/webhook/*')
global without sharing class StripeWebhookHandler {
    @HttpPost
    global static void handleEvent() {
        RestRequest req = RestContext.request;
        String payload = req.requestBody.toString();

        // CRITICAL: verify the Stripe-Signature header before trusting anything
        if (!StripeSignatureVerifier.isValid(
                payload,
                req.headers.get('Stripe-Signature'))) {
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