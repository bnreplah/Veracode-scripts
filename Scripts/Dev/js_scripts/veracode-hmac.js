


async function makeVeracodeHMACCall(apiId, apiKey, method, urlPath) {

    // Generate a 32-character hex nonce
    const nonce = Array.from(crypto.getRandomValues(new Uint8Array(16)))
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');
    
    // Get timestamp in milliseconds
    const ts = Date.now().toString();
    
    const urlBase = "http://api.veracode.com";
    
    // Helper function to perform HMAC-SHA256
    async function hmacSha256(key, message) {
        const encoder = new TextEncoder();
        
        // If key is a hex string, convert to bytes
        let keyBytes;
        if (typeof key === 'string' && /^[0-9a-f]+$/i.test(key)) {
            keyBytes = new Uint8Array(key.match(/.{1,2}/g).map(byte => parseInt(byte, 16)));
        } else {
            keyBytes = encoder.encode(key);
        }
        
        const cryptoKey = await crypto.subtle.importKey(
            'raw',
            keyBytes,
            { name: 'HMAC', hash: 'SHA-256' },
            false,
            ['sign']
        );
        
        const messageBytes = encoder.encode(message);
        const signature = await crypto.subtle.sign('HMAC', cryptoKey, messageBytes);
        
        // Convert to hex string
        return Array.from(new Uint8Array(signature))
            .map(b => b.toString(16).padStart(2, '0'))
            .join('');
    }//end hmacSha256 

    
    // Helper function to convert hex nonce to bytes and then HMAC
    async function hmacSha256WithHexKey(hexKey, message) {
        const encoder = new TextEncoder();
        
        // Convert hex key to bytes
        const keyBytes = new Uint8Array(hexKey.match(/.{1,2}/g).map(byte => parseInt(byte, 16)));
        
        const cryptoKey = await crypto.subtle.importKey(
            'raw',
            keyBytes,
            { name: 'HMAC', hash: 'SHA-256' },
            false,
            ['sign']
        );
        
        const messageBytes = encoder.encode(message);
        const signature = await crypto.subtle.sign('HMAC', cryptoKey, messageBytes);
        
        // Convert to hex string
        return Array.from(new Uint8Array(signature))
            .map(b => b.toString(16).padStart(2, '0'))
            .join('');

    }//end hmacSha256WithHexKey
    
    // Step 1: Encrypt nonce with API key
    // First convert nonce from hex to bytes for hashing
    const nonceBytes = new Uint8Array(nonce.match(/.{1,2}/g).map(byte => parseInt(byte, 16)));
    const encryptedNonce = await hmacSha256WithHexKey(apiKey, String.fromCharCode(...nonceBytes));
    
    // Step 2: Encrypt timestamp with encrypted nonce
    const encryptedTimestamp = await hmacSha256WithHexKey(encryptedNonce, ts);
    
    // Step 3: Create signing key
    const signingKey = await hmacSha256WithHexKey(encryptedTimestamp, "vcode_request_version_1");
    
    // Step 4: Create data string and signature
    const data = `id=${apiId}&host=api.veracode.com&url=${urlPath}&method=${method}`;
    const signature = await hmacSha256WithHexKey(signingKey, data);
    
    // Step 5: Create authorization header
    const authHeader = `VERACODE-HMAC-SHA-256 id=${apiId},ts=${ts},nonce=${nonce},sig=${signature}`;
    
    // Step 6: Make the API call
    try {
        const response = await fetch(`${urlBase}${urlPath}`, {
            method: method,
            headers: {
                'Authorization': authHeader,
                'Content-Type': 'application/json'
            }
        });
        
        return response;
    } catch (error) {
        console.error('API call failed:', error);
        throw error;
    }

}//end makeVeracodeHMACCall

// Example usage:
// const response = await makeCall('your-api-id', 'your-api-key', 'GET', '/healthcheck/status');
// const data = await response.json();

console.log("Test Call: " , makeVeracodeHMACCall("","",'GET','/healthcheck/status'));
