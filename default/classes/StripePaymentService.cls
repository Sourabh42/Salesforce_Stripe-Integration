public with sharing class StripePaymentService {
    @AuraEnabled
    public static Map<String,Object> createPaymentIntent(Decimal amount, String currencyIso) {
        system.debug('amount---'+amount);
        system.debug('currencyIso---'+currencyIso);
        Map<String,Object> returnMap = new Map<String,Object>();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.stripe.com/v1/payment_intents');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        // Stripe uses HTTP Basic: secret key as username, empty password
        String secretKey = System.label.secret_Key;
        Blob headerValue = Blob.valueOf(secretKey + ':');
        req.setHeader('Authorization',
            'Basic ' + EncodingUtil.base64Encode(headerValue));
        Integer amountInCents = (Integer)(amount * 100);
        String body = 'amount=' + amountInCents
                    + '&currency=' + currencyIso.toLowerCase()
                    + '&automatic_payment_methods[enabled]=true';
        req.setBody(body);

        HttpResponse res = new Http().send(req);
        Map<String, Object> resp =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
         system.debug('response=---'+res.getBody());
        returnMap.put('clientSecret',resp.get('client_secret'));
        return returnMap;
        }
}
