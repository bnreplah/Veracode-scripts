// based on https://gist.github.com/mrpinghe/f44479f2270ea36bf3b7cc958cc76cc0
// changed from the Node.js Crypto module to the Web Crypto API instead
// go to https://api.veracode.com/appsec and execute this script in the Chrome JavaScript console

const id = "YOUR_API_CREDENTIALS_ID";
const key = "YOUR_API_CREDENTIALS_KEY";

const preFix = "VERACODE-HMAC-SHA-256";
const verStr = "vcode_request_version_1";

var host = "api.veracode.com";

var hmac256 = async (data, key) => {
	var key_ = await crypto.subtle.importKey("raw", key, { name: "HMAC", hash: "SHA-256" }, true, ["sign"]);
	return await crypto.subtle.sign("HMAC", key_, data);
}

var getByteArray = (hex) => {
	var bytes = [];

	for(var i = 0; i < hex.length-1; i+=2){
	    bytes.push(parseInt(hex.substr(i, 2), 16));
	}

	// signed 8-bit integer array (byte array)
	return Int8Array.from(bytes);
}

var getHost = () => {
	return host;
}

var generateHeader = async (url, method) => {

	var data = `id=${id}&host=${host}&url=${url}&method=${method}`;
	var timestamp = (new Date().getTime()).toString();
	var nonce = hex(window.crypto.getRandomValues(new Uint8Array(16)));

	// calculate signature
	var hashedNonce = await hmac256(getByteArray(nonce), getByteArray(key));
	var hashedTimestamp = await hmac256(buffer(timestamp), getByteArray(hex(hashedNonce)));
	var hashedVerStr = await hmac256(buffer(verStr), getByteArray(hex(hashedTimestamp)));
	var signature = hex(await hmac256(buffer(data), getByteArray(hex(hashedVerStr))));

	return `${preFix} id=${id},ts=${timestamp},nonce=${nonce},sig=${signature}`;
}

// https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/digest#Converting_a_digest_to_a_hex_string
var hex = (buffer) => Array.from(new Uint8Array(buffer)).map(n => n.toString(16).padStart(2, "0")).join("");

var buffer = (string) => new TextEncoder("utf-8").encode(string);

// test
var method = "GET";
var url = "/appsec/v1/applications";
var VERACODE_AUTH_HEADER = await generateHeader(url, method);
var data = await fetch(`https://${host}${url}`, { method: method, headers: { "Authorization": VERACODE_AUTH_HEADER }}).then(response => response.json());
console.log(data._embedded.applications.map(o => o.profile.name));