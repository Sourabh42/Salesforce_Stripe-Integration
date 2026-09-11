public with sharing class StripeSignatureVerifier {

    // Reject events older than this to block replay attacks (Stripe default: 5 min)
    private static final Long TOLERANCE_SECONDS = 300;

    public static Boolean isValid(String payload, String sigHeader) {
        if (String.isBlank(payload) || String.isBlank(sigHeader)) {
            return false;
        }

        // Signing secret from Stripe dashboard: whsec_...
        // Store in a Protected Custom Setting / Custom Metadata — not hardcoded.
        String signingSecret = System.Label.signingSecret;

        // 1. Parse the header into t= and v1=
        String timestamp;
        List<String> v1Signatures = new List<String>();
        for (String part : sigHeader.split(',')) {
            List<String> kv = part.trim().split('=', 2);
            if (kv.size() != 2) continue;
            String key = kv[0].trim();
            String val = kv[1].trim();
            if (key == 't') {
                timestamp = val;
            } else if (key == 'v1') {
                v1Signatures.add(val);
            }
        }

        if (String.isBlank(timestamp) || v1Signatures.isEmpty()) {
            return false;
        }

        // 2. Reject if timestamp is outside tolerance (replay protection)
        Long eventTime = Long.valueOf(timestamp);
        Long nowSeconds = DateTime.now().getTime() / 1000;
        if (Math.abs(nowSeconds - eventTime) > TOLERANCE_SECONDS) {
            return false;
        }

        // 3. Compute expected signature over "timestamp.payload"
        String signedPayload = timestamp + '.' + payload;
        Blob mac = Crypto.generateMac(
            'hmacSHA256',
            Blob.valueOf(signedPayload),
            Blob.valueOf(signingSecret)
        );
        String expected = EncodingUtil.convertToHex(mac); // Stripe v1 is lowercase hex

        // 4. Constant-time compare against each v1 candidate
        for (String candidate : v1Signatures) {
            if (secureEquals(expected, candidate)) {
                return true;
            }
        }
        return false;
    }

    // Timing-safe comparison to avoid leaking match info via response time
    private static Boolean secureEquals(String a, String b) {
        if (a == null || b == null || a.length() != b.length()) {
            return false;
        }
        Integer diff = 0;
        for (Integer i = 0; i < a.length(); i++) {
            diff |= (a.charAt(i) ^ b.charAt(i));
        }
        return diff == 0;
    }
}