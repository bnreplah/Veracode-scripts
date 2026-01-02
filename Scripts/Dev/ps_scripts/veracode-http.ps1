# PowerShell script to make HMAC authenticated VERACODE calls
param (
    [string]$VERACODE_ID,
    [string]$VERACODE_KEY,
    [string]$METHOD,
    [string]$URLPATH
)

$NONCE = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$TS = [math]::Floor((Get-Date -UFormat %s) * 1000000)
$URLBASE = "https://api.veracode.com"

function HMAC-SHA256 {
    param (
        [string]$data,
        [string]$key
    )
    $hmacsha256 = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha256.Key = [Text.Encoding]::UTF8.GetBytes($key)
    $hash = $hmacsha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($data))
    return ($hash | ForEach-Object ToString X2) -join ""
}

$encryptedNonce = HMAC-SHA256 -data $NONCE -key $VERACODE_KEY
$encryptedTimestamp = HMAC-SHA256 -data $TS -key $encryptedNonce
$signingKey = HMAC-SHA256 -data "vcode_request_version_1" -key $encryptedTimestamp

$DATA = "id=$VERACODE_ID&host=api.VERACODE.com&url=$URLPATH&method=$METHOD"
$signature = HMAC-SHA256 -data $DATA -key $signingKey
$VERACODE_AUTH_HEADER = "VERACODE-HMAC-SHA-256 id=$VERACODE_ID,ts=$TS,nonce=$NONCE,sig=$signature"

Invoke-RestMethod -Uri "$URLBASE$URLPATH" -Method $METHOD -Headers @{Authorization=$VERACODE_AUTH_HEADER}