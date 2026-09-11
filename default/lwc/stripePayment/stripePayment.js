import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import createPaymentIntent from '@salesforce/apex/StripePaymentService.createPaymentIntent';

const STRIPE_JS = 'https://js.stripe.com/v3/';

export default class StripePayment extends LightningElement {
    @api publishableKey ='pk_test_51Set9zFnSk5MC5IuhKZagxr1N6dvqFE71ME2fXpVGKrD1HkRp2LhLh37ouNcZxKkCoILUSC5Ep19W4uSub24gLPd00d89K962x';   // pk_live_... (publishable key is safe to expose)
    @api amount =200;           // e.g. 2000 = $20.00
    @api recordId;         // Order/Opportunity to pay for

    stripe;
    elements;
    clientSecret;
    loading = false;
    message;

    async connectedCallback() {
        try {
            // imperative Apex — runs ONCE, on demand, not reactively
            const intent = await createPaymentIntent({
                amount: this.amount,
                currencyIso: 'INR'
            });
            this.clientSecret = intent.clientSecret;
            await this.initStripe();
        } catch (e) {
          //  this.message = e.body?.message ?? e.message;
        }
    }

    async initStripe() {
        await loadScript(this, STRIPE_JS);
        this.stripe = window.Stripe(this.publishableKey);
        this.elements = this.stripe.elements({ clientSecret: this.clientSecret });
        console.log('elements---', this.elements);
        this.elements.create('payment')
            .mount(this.template.querySelector('.payment-element'));
    }

    async handlePay() {
        this.loading = true;
        this.message = null;
        const { error } = await this.stripe.confirmPayment({
            elements: this.elements,
            confirmParams: { return_url: window.location.origin + '/payment-complete' },
            redirect: 'if_required'
        });
        this.loading = false;
        this.message = error ? error.message : 'Payment successful!';
        if (!error) this.dispatchEvent(new CustomEvent('success'));
    }
}
