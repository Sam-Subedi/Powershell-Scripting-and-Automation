#Requires -Version 5.1
<#
.SYNOPSIS  Encrypt and decrypt passwords for use in automation scripts — no plaintext storage.
.DESCRIPTION
    DPAPI    : Encrypt with Windows user+machine binding (most secure, same machine only).
    AES      : Encrypt with a key file (cross-machine, share key file securely).
    Actions  : Encrypt | Decrypt | EncryptAES | DecryptAES | GenerateKey
.NOTES
    Usage   : .\13-Encrypt-Decrypt-Script-Passwords.ps1 -Action GenerateKey
              .\13-Encrypt-Decrypt-Script-Passwords.ps1 -Action EncryptAES -OutputFile pwd.txt -KeyFile aes.key
              .\13-Encrypt-Decrypt-Script-Passwords.ps1 -Action DecryptAES -InputFile pwd.txt  -KeyFile aes.key
#>
param(
    [ValidateSet('Encrypt','Decrypt','EncryptAES','DecryptAES','GenerateKey')]
    [string]$Action     = 'Encrypt',
    [string]$OutputFile = '.\encrypted_password.txt',
    [string]$KeyFile    = '.\aes_key.key',
    [string]$InputFile
)
switch ($Action) {
    'GenerateKey' {
        $key = New-Object byte[] 32
        [System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($key)
        $key | Set-Content -Path $KeyFile -Encoding Byte
        Write-Host "AES key saved: $KeyFile" -ForegroundColor Green
        Write-Host "IMPORTANT: Protect this file — anyone with it can decrypt your passwords!" -ForegroundColor Red
    }
    'Encrypt' {
        $s = Read-Host 'Password to encrypt' -AsSecureString
        ConvertFrom-SecureString -SecureString $s | Set-Content -Path $OutputFile
        Write-Host "DPAPI-encrypted password saved: $OutputFile" -ForegroundColor Green
        Write-Host "Can only be decrypted by THIS user on THIS machine." -ForegroundColor Yellow
    }
    'Decrypt' {
        $f = if ($InputFile) { $InputFile } else { $OutputFile }
        $s = ConvertTo-SecureString (Get-Content $f)
        $p = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
        Write-Host "Decrypted: $p" -ForegroundColor Green
    }
    'EncryptAES' {
        if (-not (Test-Path $KeyFile)) { throw "Key file not found. Run -Action GenerateKey first." }
        $key = Get-Content -Path $KeyFile -Encoding Byte
        $s   = Read-Host 'Password to encrypt' -AsSecureString
        ConvertFrom-SecureString -SecureString $s -Key $key | Set-Content -Path $OutputFile
        Write-Host "AES-encrypted password saved: $OutputFile" -ForegroundColor Green
    }
    'DecryptAES' {
        $f = if ($InputFile) { $InputFile } else { $OutputFile }
        if (-not (Test-Path $f))       { throw "File not found: $f" }
        if (-not (Test-Path $KeyFile)) { throw "Key file not found: $KeyFile" }
        $key = Get-Content -Path $KeyFile -Encoding Byte
        $s   = ConvertTo-SecureString (Get-Content $f) -Key $key
        $p   = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
        Write-Host "Decrypted: $p" -ForegroundColor Green
    }
}
Write-Host @'
--- Use encrypted password in a script ---
$key    = Get-Content "aes_key.key" -Encoding Byte
$secure = ConvertTo-SecureString (Get-Content "encrypted_password.txt") -Key $key
# Pass $secure to any cmdlet that accepts a SecureString password
'@ -ForegroundColor DarkCyan
