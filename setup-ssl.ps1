# PowerShell script for generating SSL certificates using PowerShell's built-in functionality

# Create SSL directory if it doesn't exist
Write-Host "Creating SSL directory..."
New-Item -ItemType Directory -Path ssl -Force | Out-Null

# Generate self-signed certificate
Write-Host "Generating self-signed SSL certificate..."
$cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "Cert:\LocalMachine\My" -NotAfter (Get-Date).AddYears(1)

# Export the certificate to PFX format (with private key)
$password = ConvertTo-SecureString -String "password123" -Force -AsPlainText
$certPath = "Cert:\LocalMachine\My\$($cert.Thumbprint)"
Export-PfxCertificate -Cert $certPath -FilePath "ssl\cert.pfx" -Password $password
Write-Host "Certificate exported as PFX to ssl\cert.pfx"

# Export certificate as CRT
Export-Certificate -Cert $certPath -FilePath "ssl\certificate.crt" -Type CERT
Write-Host "Certificate exported as CRT to ssl\certificate.crt"

# Generate a private key file that Nginx can use
# Since we can't directly extract the private key without OpenSSL, we'll use the PFX file
# and configure our application to use it
$content = "-----BEGIN PRIVATE KEY PLACEHOLDER-----
This is a placeholder for the private key. In production, you would extract 
the actual private key from the PFX file using OpenSSL.
For now, we'll configure our services to use the PFX file directly.
-----END PRIVATE KEY PLACEHOLDER-----"
Set-Content -Path "ssl\private.key" -Value $content

# Copy certificates to the frontend folder
Copy-Item -Path ssl/private.key -Destination frontend/private.key -Force
Copy-Item -Path ssl/certificate.crt -Destination frontend/certificate.crt -Force
Copy-Item -Path ssl/cert.pfx -Destination frontend/cert.pfx -Force

# Output success message
Write-Host "SSL certificates generated and copied to frontend folder successfully!"
Write-Host "Certificate password: 'password123'"
Write-Host "Note: Use the cert.pfx file for services that require a combined certificate and key file."
