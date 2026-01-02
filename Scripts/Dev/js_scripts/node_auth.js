var crypto = require('crypto');

const id = process.env.API_ID; // your API ID, reading from environment variable
const key = process.env.KEY; // your API key, reading from environment variable

const preFix = "VERACODE-HMAC-SHA-256";
const verStr = "vcode_request_version_1";

var resthost = "api.veracode.com"; // rest host
var xmlhost = "analysiscenter.veracode.com"; // xml host

var hmac256 = (data, key, format) => {
	var hash = crypto.createHmac('sha256', key).update(data);
	// no format = Buffer / byte array
	return hash.digest(format);
}

var getByteArray = (hex) => {
	var bytes = [];

	for(var i = 0; i < hex.length-1; i+=2){
	    bytes.push(parseInt(hex.substr(i, 2), 16));
	}

	// signed 8-bit integer array (byte array)
	return Int8Array.from(bytes);
}

var getHost = (xml) => {
	if (xml) {
		return xmlhost;
	}
	return resthost;
}

var generateHeader = (url, method, xml) => {

	var host = getHost(xml);

	var data = `id=${id}&host=${host}&url=${url}&method=${method}`;
	var timestamp = (new Date().getTime()).toString();
	var nonce = crypto.randomBytes(16).toString("hex");

	// calculate signature
	var hashedNonce = hmac256(getByteArray(nonce), getByteArray(key));
	var hashedTimestamp = hmac256(timestamp, hashedNonce);
	var hashedVerStr = hmac256(verStr, hashedTimestamp);
	var signature = hmac256(data, hashedVerStr, 'hex');

	return `${preFix} id=${id},ts=${timestamp},nonce=${nonce},sig=${signature}`;
}

module.exports = {
	getHost,
	generateHeader
}