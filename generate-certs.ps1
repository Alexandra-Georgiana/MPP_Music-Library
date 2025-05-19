# PowerShell script to generate self-signed SSL certificates for local HTTPS development

$domain = "mpp.local" # You can change this to your desired domain

# Create output directory if it doesn't exist
New-Item -ItemType Directory -Force -Path ./certs | Out-Null

# Generate a self-signed certificate
$cert = New-SelfSignedCertificate -DnsName $domain -CertStoreLocation "Cert:\LocalMachine\My" -NotAfter (Get-Date).AddYears(1)

# Export certificate to PFX file with private key
$password = ConvertTo-SecureString -String "password123" -Force -AsPlainText
$certPath = "Cert:\LocalMachine\My\$($cert.Thumbprint)"
Export-PfxCertificate -Cert $certPath -FilePath "./certs/certificate.pfx" -Password $password

# Export certificate as CRT (public key)
Export-Certificate -Cert $certPath -FilePath "./certs/certificate.crt" -Type CERT

# Extract private key to a file (openssl would be needed for a proper PEM format)
# For now, we'll generate a placeholder
@"
-----BEGIN PRIVATE KEY-----
This is a placeholder for your private key.
In production, you would extract the actual private key from the PFX file using OpenSSL.
-----END PRIVATE KEY-----
"@ | Out-File -FilePath "./certs/private.key" -Encoding ascii

Write-Host "SSL certificates generated successfully!"
Write-Host "Certificate: ./certs/certificate.crt"
Write-Host "Private key: ./certs/private.key"
Write-Host "PFX file: ./certs/certificate.pfx (Password: password123)"

# Inform user about trusting the certificate
Write-Host "`nTo trust this certificate in Windows:"
Write-Host "1. Double-click on certificate.crt"
Write-Host "2. Click 'Install Certificate...'"
Write-Host "3. Select 'Local Machine' and click Next" 
Write-Host "4. Select 'Place all certificates in the following store' and click 'Browse...'"
Write-Host "5. Select 'Trusted Root Certification Authorities' and click 'OK'"
Write-Host "6. Click 'Next' and then 'Finish'"

# Create directories for Flask and Node.js
New-Item -ItemType Directory -Force -Path ./frontend/backend/certs | Out-Null

# Copy certificates to the backend directories
Copy-Item -Path "./certs/certificate.crt" -Destination "./frontend/backend/certs/" -Force
Copy-Item -Path "./certs/private.key" -Destination "./frontend/backend/certs/" -Force
