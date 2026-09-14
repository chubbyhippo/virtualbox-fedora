param(
    [string]$OutputPath = "zscaler-root-ca.crt"
)

$cert = Get-ChildItem -Path Cert:\LocalMachine\Root, Cert:\CurrentUser\Root |
    Where-Object { $_.Subject -like "*Zscaler*" } |
    Select-Object -First 1

if (-not $cert) {
    Write-Error "No Zscaler root CA found in the Windows certificate store."
    exit 1
}

$der = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
$b64 = [System.Convert]::ToBase64String($der, [System.Base64FormattingOptions]::InsertLineBreaks)
"-----BEGIN CERTIFICATE-----`n$b64`n-----END CERTIFICATE-----" |
    Set-Content -Path $OutputPath -Encoding ascii

Write-Host "Exported '$($cert.Subject)' to $OutputPath"
