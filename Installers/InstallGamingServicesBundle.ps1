[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [string]
    $AppxPath,

    [Parameter(Mandatory = $false)]
    [string]
    $AppxDepDirPath
)

$Error.Clear();

if (-not $AppxPath) {
    $AppxPath = Join-Path $PSScriptRoot "GamingServices.appxbundle";
}

if (-not (test-path $AppxPath)) {
    Write-Output "ERROR: Appx not found: $AppxPath";
    exit 1;
}
   
if (-not $AppxDepDirPath) {
    $AppxDepDirPath = (get-item $AppxPath).Directory.FullName;
}

$systemVolume = Get-AppxVolume | Where-Object -Property IsSystemVolume -eq $True | Select-Object -First 1;

if (-not $systemVolume) {
    Write-Output "ERROR: System volume not found.";
    exit 1;
}

Write-Output ("System volume found.`n{0}" -f ($systemVolume | Format-List | Out-String).trim());

$systemRoot = [System.IO.path]::GetPathRoot($systemVolume.PackageStorePath);

if (-not $systemRoot) {
    Write-Output "ERROR: System root not found.";
    exit 1;
}

Write-Output "System root found: $systemRoot";

$package = Get-AppxPackage -Name Microsoft.GamingServices* | Sort-Object -Property Version -Descending | Select-Object -First 1;
$isOldPackagePresent = $false;

if ($package) {
    Write-Output ("Version {0} of {1} was found already installed on the PC.`n{2}" -f $package.Version, $package.Name, ($package | Format-List | Out-String).trim());

    $isOldPackagePresent = (([Version]$package.Version -lt [Version]'25.94.27002.0') -or ([Version]$package.Version -eq [Version]'1.43.2002.0'));

    if ($isOldPackagePresent) {
        Write-Output "Uninstalling $($package.PackageFullName) version $($package.Version)";
        remove-appxpackage -allusers $package.PackageFullName -ErrorAction Continue;

        if ($Error) {
            Write-Output "Remove-AppxPackage failed for $($package.PackageFullName)";
        }
        else {
            Write-Output "Remove-AppxPackage completed for $AppxPath";
        }
    }
}
else {
    Write-Output 'No versions of Microsoft.GamingServices were found installed on the PC.';
}

if (($package -eq $null) -or $isOldPackagePresent) {
    Write-Output "Installing $AppxPath Version 25.94.27002.0 Volume $systemRoot";

    $allDepsFound = $TRUE;
    [string[]]$depPackageNames = 'Microsoft.NET.Native.Runtime.2.2', 'Microsoft.NET.Native.Framework.2.2', 'Microsoft.VCLibs.x64.14.00';
    $dependencyPaths = $depPackageNames | ForEach-Object { Join-Path -Path $AppxDepDirPath -ChildPath "$_.appx" };
    ForEach ($dep in $dependencyPaths) { if (-not (test-path $dep)) { $allDepsFound = $FALSE; } };

    if ($allDepsFound) {
        Write-Output "Installing $AppxPath Version 25.94.27002.0 Volume $systemRoot -DependencyPath $dependencyPaths";
        add-appxpackage -forceApplicationShutdown -path $AppxPath -Volume $systemRoot -DependencyPath $dependencyPaths -ErrorAction Continue;
    }
    else {
        Write-Output "Installing $AppxPath Version 25.94.27002.0 Volume $systemRoot";
        add-appxpackage -forceApplicationShutdown -path $AppxPath -Volume $systemRoot -ErrorAction Continue;
    }

    if ($Error) {
        Write-Output "ERROR: Add-AppxPackage failed for $AppxPath";
        $guid = ($error -split ' ' | select -Last 1) -as [Guid];
        if ($guid) {
            Write-Output "Get-AppPackageLog -ActivityID $guid";
            Get-AppPackageLog -ActivityID $guid;
        }
    }
    else {
        Write-Output "Add-AppxPackage completed for $AppxPath";
    }
}
else {
    Write-Output "No installation needed as version $($package.Version) of $($package.Name) was found already installed on the PC.";
}

exit ($Error.Count);

# SIG # Begin signature block
# MIImTAYJKoZIhvcNAQcCoIImPTCCJjkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCn2ER4Q/oiZ+/i
# NBjooxjk6m+eJvsvD4i2amM+G5/3MqCCC2cwggTvMIID16ADAgECAhMzAAAFp7iP
# +5ddNYTsAAAAAAWnMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTAwHhcNMjQwODIyMTkyNTU3WhcNMjUwNzA1MTkyNTU3WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCWGlTKjYt60rB8oNyPWJUGQV2NGwlRXKJg3484q2nJiv9+Frz96fGoXlblIeJ3
# xqQxEoCEDYjjbYClgx31MZcoRqJD0sKjNtYDKA0NiSdOJQut3+HN0rSx74yqobDB
# P8AKAyWANZitUQHnPH1EkTXMdRlnJnD1RtFljMYOJnrxfqrAdtNNxU1pIYYmY6oD
# 8dye81i9RHxSJGEgfMnEIpn/1ySkikTV+NOHFj1QH7+SHZWYNcdgL48QSa1jC30A
# i6MKLh91FOsCsuNU0cTC6z6QkP51l9dU8B+xnvZa2/WzvJhByZnjXS+tVeN2KB5E
# p0seOtuFwvI6KoOXrETKCDg7AgMBAAGjggFuMIIBajAfBgNVHSUEGDAWBgorBgEE
# AYI3PQYBBggrBgEFBQcDAzAdBgNVHQ4EFgQUUhW6zVNwhzmLbscozYppwd8fKxIw
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwODY1KzUwMjcwMzAfBgNVHSMEGDAWgBTm/F97uyIAWORyTrX0
# IXQjMubvrDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5j
# b20vcGtpL2NybC9wcm9kdWN0cy9NaWNDb2RTaWdQQ0FfMjAxMC0wNy0wNi5jcmww
# WgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpL2NlcnRzL01pY0NvZFNpZ1BDQV8yMDEwLTA3LTA2LmNydDAMBgNV
# HRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQAl1cQIQ+FD/ubaWIiMg8wQtEx3
# SksQ5r6qAgferOe6TZ5bmTcMj2VUkHLrvmhScoRe9pQ/CqwZ676YuM90tiqPrMDj
# XO8kLCA+kTeDZoKQL0MI2ShbDhXrDIsui9hGNhd8PwGTWQksnoO4HxqGG2Mfiqsn
# OgMo9HimmTF2/H1XLc/g2TPpF8GyXAco7khch4l1hIIpmVEZN6ZFCk2/kOf7m2sC
# l8h5+BWQDmSaECtI2xc5SLbqot1isWvFiERtaw9xQb31MWYas2l2/XdcbH7QFYpK
# pG4dDZhKIdlRVmYpUyRaNOZWNwNc7G6bzKIC3HAGFOIEc4aDQu2yT/q0yJ7WMIIG
# cDCCBFigAwIBAgIKYQxSTAAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0
# IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMTAwNzA2MjA0MDE3
# WhcNMjUwNzA2MjA1MDE3WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDEw
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6Q5kUHlntcTj/QkATJ6U
# rPdWaOpE2M/FWE+ppXZ8bUW60zmStKQe+fllguQX0o/9RJwI6GWTzixVhL99COMu
# K6hBKxi3oktuSUxrFQfe0dLCiR5xlM21f0u0rwjYzIjWaxeUOpPOJj/s5v40mFfV
# HV1J9rIqLtWFu1k/+JC0K4N0yiuzO0bj8EZJwRdmVMkcvR3EVWJXcvhnuSUgNN5d
# pqWVXqsogM3Vsp7lA7Vj07IUyMHIiiYKWX8H7P8O7YASNUwSpr5SW/Wm2uCLC0h3
# 1oVH1RC5xuiq7otqLQVcYMa0KlucIxxfReMaFB5vN8sZM4BqiU2jamZjeJPVMM+V
# HwIDAQABo4IB4zCCAd8wEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFOb8X3u7
# IgBY5HJOtfQhdCMy5u+sMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjR
# PZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNy
# bDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MIGd
# BgNVHSAEgZUwgZIwgY8GCSsGAQQBgjcuAzCBgTA9BggrBgEFBQcCARYxaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL1BLSS9kb2NzL0NQUy9kZWZhdWx0Lmh0bTBABggr
# BgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBQAG8AbABpAGMAeQBfAFMAdABhAHQA
# ZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAGnTvV08pe8QWhXi4UNMi
# /AmdrIKX+DT/KiyXlRLl5L/Pv5PI4zSp24G43B4AvtI1b6/lf3mVd+UC1PHr2M1O
# HhthosJaIxrwjKhiUUVnCOM/PB6T+DCFF8g5QKbXDrMhKeWloWmMIpPMdJjnoUdD
# 8lOswA8waX/+0iUgbW9h098H1dlyACxphnY9UdumOUjJN2FtB91TGcun1mHCv+KD
# qw/ga5uV1n0oUbCJSlGkmmzItx9KGg5pqdfcwX7RSXCqtq27ckdjF/qm1qKmhuyo
# EESbY7ayaYkGx0aGehg/6MUdIdV7+QIjLcVBy78dTMgW77Gcf/wiS0mKbhXjpn92
# W9FTeZGFndXS2z1zNfM8rlSyUkdqwKoTldKOEdqZZ14yjPs3hdHcdYWch8ZaV4XC
# v90Nj4ybLeu07s8n07VeafqkFgQBpyRnc89NT7beBVaXevfpUk30dwVPhcbYC/GO
# 7UIJ0Q124yNWeCImNr7KsYxuqh3khdpHM2KPpMmRM19xHkCvmGXJIuhCISWKHC1g
# 2TeJQYkqFg/XYTyUaGBS79ZHmaCAQO4VgXc+nOBTGBpQHTiVmx5mMxMnORd4hzbO
# TsNfsvU9R1O24OXbC2E9KteSLM43Wj5AQjGkHxAIwlacvyRdUQKdannSF9PawZSO
# B3slcUSrBmrm1MbfI5qWdcUxgho7MIIaNwIBATCBlTB+MQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBT
# aWduaW5nIFBDQSAyMDEwAhMzAAAFp7iP+5ddNYTsAAAAAAWnMA0GCWCGSAFlAwQC
# AQUAoIHGMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsx
# DjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCD3jSXksZqBp6p/KF86p061
# sxOBnk67luNS6PH4/6OtwDBaBgorBgEEAYI3AgEMMUwwSqAkgCIATQBpAGMAcgBv
# AHMAbwBmAHQAIABXAGkAbgBkAG8AdwBzoSKAIGh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS93aW5kb3dzMA0GCSqGSIb3DQEBAQUABIIBAIYL1j/ramImWRXlGymz0tIK
# V/bda4FXLUmZr5Ch/Shef2EwdziLq+OCZLHq1XM3/dXlQBOz0RmgdmFLcpowaQJ9
# BaNyfmemCVYmc2qnVyMXQ3HEhdss7Ki80XQezADAOWoE4iAHwtoL6ICtSuMHMi+a
# NIOgo4qbPZdmrjqmsqhPlcsheK9ehALyYpzCBAgKcNYH7b2o2syvrX40UY3gJJC0
# bYEkr6hYKtuvSAc1UikBxYsqy/ZiCnKUrR0MInHIhKcTC+GRTDb9Ej07lc5I2wxH
# v1GPLvf0vhtoEfSbg/+9w0fmO6weEa55Xg2gJR9Nq+v6q0E3VhBulB8NcWcsQDSh
# ghetMIIXqQYKKwYBBAGCNwMDATGCF5kwgheVBgkqhkiG9w0BBwKggheGMIIXggIB
# AzEPMA0GCWCGSAFlAwQCAQUAMIIBWgYLKoZIhvcNAQkQAQSgggFJBIIBRTCCAUEC
# AQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEFAAQgt1cuQbGe9U4Pypl8Y4+l
# 6M/v+cFwLEeRYolAmuS+DeYCBmbrKdAjtxgTMjAyNDEwMzExNDMxMjguOTQ0WjAE
# gAIB9KCB2aSB1jCB0zELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVk
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzIxQS0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghH7MIIHKDCCBRCgAwIB
# AgITMwAAAfijoSYMDEBI/gABAAAB+DANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMDAeFw0yNDA3MjUxODMxMDhaFw0yNTEwMjIxODMx
# MDhaMIHTMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYD
# VQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJzAlBgNV
# BAsTHm5TaGllbGQgVFNTIEVTTjozMjFBLTA1RTAtRDk0NzElMCMGA1UEAxMcTWlj
# cm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAMUdt6V2Jw9gbjg3Xl7Ngrv0+ZCiPmwMPHG7TedApvxQK418i+EU
# 6jHupWkPwqnjE8YHJL2a9Sa1tDIuBdea8f1b3hoSgZqG+OQ5jnFeccse4fU5OfTQ
# JeTzTAFigCFn9u9ElgAFsUG6VSIYT1gp1Vd6LVb2oRGnfKTJqEl60+WezZNUZwe9
# ANm6vR5PMCHgt7wbsRF9hPF+dCIAB7Mmkfa6BatxK81BB5UvGJ0qt97oubgXKxTn
# BTgmSC7lRVU4BKkq1+FIl9Hraou41LSsqYCH5WmXFeXCOVyP3gsWPMAzZgaa4WDD
# ZWMXZkPWi0Q3EylrXXVqZybcpeXt4B7mKI/Mbg0NF2TcuxEkcCSCtN/q02an2mMj
# OF0itbNGmvpjuvb6PzZieEf39firnATyeMlHW6iVjN8TLwcC2MnL4oCP1iuJID6I
# NFATXM2kMA1V6XFPkzHDr1j/BwVpliUCJk2SJwBYr16lGgW6N8AHzzW7EKbzTRrv
# 9dqYNBfDvwnUX4Dx3zoSFkNA/ACwmPi7IsG83Ho261ZeDfX59sDoNrA2vEXzaA+t
# eCNKRY8v5atTbAaPVeBmQYpM1+2Y1gkYHdRQgVxqX6Q4pB40NOWDpAGpHVg09mxk
# mlGSRlWLXqSKT0wLNYHf71KIHHYi+daO7IbhyJQekElIkNuF2IUW20AhAgMBAAGj
# ggFJMIIBRTAdBgNVHQ4EFgQUvc7Gc8+e0JU+Z67f6IrS79TkO7YwHwYDVR0jBBgw
# FoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwVGltZS1T
# dGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEF
# BQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNy
# b3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/
# BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMCB4AwDQYJ
# KoZIhvcNAQELBQADggIBAGH5PBs86RFZxpe8uqF6MrQm+Nh8ekzgNPnZGgSN+n7Q
# xPbS7m1Gv8TGxwea3DYkYRR2fd0Xn3T6XOPhRdAwJeZT/MSgDvtvd0VjygxThSMY
# LWWNPLfA/XEkKYBlM8sN5RE2XmzSxANewPwk6QNhfbofI/OCsoHhG4/m4nVg4hH2
# sqB9gOf+csCScSLi8xVR2nL1sUgiqBfYZUq2UhuX11kt52pn+LbevdFE+gBslixV
# nvPeXKBT8Zv5tFCDI46fVURR+529zYNkOID0vROWUzGepwJZlInA49DVwLNsELkK
# 52J20QCfw0Ft+ai6Ow2sPQLCLaoxYWzHBuvIA3OI++C9imHv9oKARy8M0p+VA37U
# tR2SNGUbKpjRyNE2b71Fl/Wo5uknywUxLaE6OoCzl9FA//a64Ro3ZIgsOEsFOaLA
# pYKoIjTCuZ3ZNoMRZQ1xwsi6eagegaD6XPNkYTtMgs6D/YL+879hKHAFhLKhOftF
# prubmq5n73M4i31NUmNuNDmVvJXeLEvH58m5/4wzJhQIWs1dcx9EBEVhLHy0qcJD
# l2iJljRSeZZnJ39VU5unJn2rEnGLRJaY6mfRqKAppNVxQKTkT7PzzuNyHBZj0cGo
# LdNIkEsPqwXiB9NCkKvhSU/+tkge9IPYP0fE0upOm/8LdlFoaq1vkPJcOl84Hsf2
# MIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsF
# ADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UE
# AxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcN
# MjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
# cCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOThpkzn
# tHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3
# lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ3MFE
# yHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oaezOtgFt+
# jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4x
# yDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXAhjBc
# TyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9
# pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ
# 8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pn
# ol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYG
# NRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8FdsaN8cI
# FRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TASBgkrBgEE
# AYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E
# 7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwr
# BgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUF
# BwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYG
# A1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3Js
# L3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcB
# AQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kv
# Y2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUA
# A4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2
# P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J
# 6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jfZfak
# Vqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/AyeixmJ5/AL
# aoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtP
# u4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5H
# LcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEua
# bvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvB
# QUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb
# /wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784cETR
# kPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCA1YwggI+AgEB
# MIIBAaGB2aSB1jCB0zELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVk
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzIxQS0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMV
# ALZELf3m1kkOQ5xvmikczxCwhRPRoIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDqza0sMCIYDzIwMjQxMDMxMDcx
# NTU2WhgPMjAyNDExMDEwNzE1NTZaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAOrN
# rSwCAQAwBwIBAAICDAIwBwIBAAICE1IwCgIFAOrO/qwCAQAwNgYKKwYBBAGEWQoE
# AjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
# hkiG9w0BAQsFAAOCAQEACnwY5xGi8b95oCfq40P8Niw/VDSuTanjrzLXF189KTuH
# +VvbG6Mh1hVkpiopozAAJsc2ezo2iFCQNqWGbFUtYMqqzmhDOgqC1oOt124e8A77
# 1/uQu2F6vLNo+YaNeVdvkNWLa3kKFNPwKUJx1t7LqwUYUcE8v/mhb3LtlAFaE61K
# MOnWbfQuRk8dXJeSPUn6FO4PZGRQegOJxylKf7evWBpx1kx5utVO3P0TYAnsWvTM
# nTroX4g2Z2uRlmMlPTl5gZqc0ltlwR7touHQ6Ywm/cazw1JO+DHnbWoJhRWJbtae
# dE76AW1idM+w5btlIJj9CA8lw3++4HEwGrFBOaVoYTGCBA0wggQJAgEBMIGTMHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB+KOhJgwMQEj+AAEAAAH4
# MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# LwYJKoZIhvcNAQkEMSIEIF2nkcvmL0R0l/Hva0qkkwLI/JxKRRk+p2wvCrd0I33k
# MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg78wz8l8NVJAFBWLfG0eFHYzP
# dEL+cZ1Woig9yNGc91owgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMAITMwAAAfijoSYMDEBI/gABAAAB+DAiBCCG2/y6wKCQNMtCF/mtyOsPaS8B
# 6XSnGGmI3jNIThgdtzANBgkqhkiG9w0BAQsFAASCAgCyx01HR43ldFEen4Hy2uee
# E7FIwPxCx/gRWu4mDo8FoQSXM3A4dOphwSw70lIf9dzo+Wd66b2ZsxRnr5rOap3S
# RT6a9294tjhtNtN37dNlA8UNff4qCntoXJ3vCYzs3fJnEgJEEKxZJ45zCWBXM76F
# FXqGdED7H7Lc2w9z4B+s5GMWh3NlQP2jK4UE0Zjpvn3RBBJN7uuDQ7DiC/JCQvCv
# IKNhu4ZVocpQHbxl8K2gq1kI2qd6NvyrFyj1Z3XAIWZz0OkXkH/JaVOospeXSIAO
# nV3CoC0u+8NXyBxBNekGAhXRxhu+KpnnvH/KXyFvD3Qf8IWMRNh5VSQrIztZ1w4t
# 9hgd4kTRSCYS6Zpv3aMjeL1c3djAUKckfrCcRaGg6d24WkwLuyuOvJo1Y3UtjbGU
# tvu28J8RTXUTvEpUhBT+4XGY/Ka+4oLsnY1jdPezc0or+u8jhwRY5fc9AS+iiN6b
# pa9bavt3xu1QMMGJaE3/avUIAKTMzfgVlYCOAy93VykuPWz2jUZrvJBXqHs3iuVa
# rF38i0H9HqJu9tkKnjSt0fgo+yZDT4Ht9HsPkBAkBUxCNAox5RURRYYnfVwdsqxT
# zGpfQwhbtVYrnky8ZfIf++N3tzVcusG4lB1fy3M2vrtPiQEwmFniGixtco5jrxja
# 4MC85kNegt//u7ClrPOv2w==
# SIG # End signature block
