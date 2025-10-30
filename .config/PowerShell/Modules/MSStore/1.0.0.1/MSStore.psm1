################################
# Start: Internal use functions
################################

function New-CV() {
  $cv = [Convert]::ToBase64String([Guid]::NewGuid().ToByteArray(), 0, 12)

  $cv
}

function Get-AccessTokenFromSessionData() {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.SessionState]
    $SessionState
  )
    
  $connectionInfo = Get-MSStoreConnectionInfo -SessionState $SessionState

  $token = Get-AccessToken -ConnectionInfo $connectionInfo
    
  $token
}

function Get-AccessToken() {
  param(
    [Parameter(Mandatory = $true)]
    [PSCustomObject]$ConnectionInfo
  )


  $authCtx = $ConnectionInfo.AuthCtx
  $credentials = $ConnectionInfo.Credentials
  $clientId = $ConnectionInfo.ClientId
  $resource = $ConnectionInfo.Resource

  $userCredential = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserPasswordCredential"($credentials.Username, $credentials.Password)

  $token = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContextIntegratedAuthExtensions]::AcquireTokenAsync(
    $AuthCtx,
    $Resource, 
    $ClientId, 
    $userCredential).Result
        
  $token 
}

function Get-MSStoreConnectionInfo {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.SessionState]
    $SessionState
  )
    
  if ($sessionState.PSVariable -eq $null) {
    throw "unable to access SessionState.PSVariable, Please call Connect-MSStore before calling any other Powershell CmdLet for the MSStore Module"
  }

  $connectionInfo = $sessionState.PSVariable.GetValue("ConnectionInfo");

  if ($connectionInfo -eq $null) {
    throw "You must call the Connect-MSStore cmdlet before calling any other cmdlets"
  }

  return $connectionInfo
}

function Get-MSStoreBaseUri() {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.SessionState]
    $SessionState
  )

  $connectionInfo = Get-MSStoreConnectionInfo -SessionState $SessionState

  $connectionInfo.MtsBaseUri

}

################################
# End: Internal use functions
################################


################################
# Start: Exported functions
################################

<#
    .SYNOPSIS
    Method to retrieve token for access to MSStore
#>
function Grant-MSStoreClientAppAccess() {
  param(
    [string]
    $ClientId = "295a96a4-53fa-41ee-9a49-91fb99f95a00",

    [Uri]
    $RedirectUri = [uri] "http://localhost/mts/tools",

    [string]
    $Resource = "https://onestore.microsoft.com"
  )

  $authorityUrl = "https://login.windows.net/common"
    
  $authCtx = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" $authorityUrl

  $platformParams = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" ([Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Always)

  $token = $authCtx.AcquireTokenAsync($Resource, $ClientId, $RedirectUri, $platformParams).Result

  if ($token -eq $null) {
    Write-Error "Unable to properly authorize the client application $($ClientId)"
  }
}

<#
    .SYNOPSIS
    Method to connect to MSStore with the credentials specified
#>
function Connect-MSStore() {
  [CmdletBinding()]
  param(
    # Parameter help description
    [Parameter(Mandatory = $true)]
    [pscredential]
    $Credentials,

    [string]
    $ClientId = "295a96a4-53fa-41ee-9a49-91fb99f95a00",

    [Uri]
    $RedirectUri = [uri] "http://localhost/mts/tools",

    [string]
    $Resource = "https://onestore.microsoft.com",

    [string]
    $MtsBaseUri = "https://bspmts.mp.microsoft.com"
  )

  $authorityUrl = "https://login.windows.net/common"
  $authCtx = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" $authorityUrl

  $connectionInfo = [PSCustomObject]@{
    AuthCtx     = $authCtx
    Credentials = $Credentials
    Resource    = $Resource 
    ClientId    = $ClientId
    MtsBaseUri  = $MtsBaseUri.TrimEnd("/") # no trailing slashes allowed
  }

  $token = Get-AccessToken -ConnectionInfo $connectionInfo

  if ($token -eq $null) {
    throw "Unable to retrieve token for user '$($Credentials.Username)', ensure you've allowed access to the client application by calling Grant-MSStoreClientAppAccess"
  }


  $sessionState = $PSCmdlet.SessionState

  $sessionState.PSVariable.Set("ConnectionInfo", $connectionInfo)
}

<#
    .SYNOPSIS
    Method to retrieve applications from tenant's inventory
#>
function Get-MSStoreInventory() {
  [CmdletBinding()]
  param(
    [string] $ContinuationToken,
    [switch] $ExcludeOnline,
    [switch] $IncludeOffline,
    [int] $MaxResults = 25,
    [System.Nullable[DateTime]]$ModifiedSince = $null 
  )

  $token = Get-AccessTokenFromSessionData -SessionState $PSCmdlet.SessionState
  $cv = New-CV
  $mtsBaseUri = Get-MSStoreBaseUri -SessionState $PSCmdlet.SessionState
  $mDollarBaseUri = "https://displaycatalog.mp.microsoft.com"

  if ($ExcludeOnline -and $ExcludeOffline) {
    throw "Cannot exclude both online and offline from the inventory query"
  }

  $queryParameters = ""

  if (-not $ExcludeOnline) {
    $queryParameters += "licenseTypes=Online&"
  }

  if ($IncludeOffline) {
    $queryParameters += "licenseTypes=Offline&"
  }

  if (-not [String]::IsNullOrWhiteSpace($ContinuationToken)) {
    $queryParameters += "continuationtoken=$($ContinuationToken)&"
  }

  if ($MaxResults -ne $null) {
    $queryParameters += "maxResults=$($MaxResults)&"
  }

  if ($ModifiedSince -ne $null) {
    $queryParameters += "modifiedSince=$($ModifiedSince.Value.ToString("O"))&"
  }

  $queryParameters = $queryParameters.TrimEnd("&");
  $queryParameters += "&IncludeRemoved=false&includeSubscription=true"

  $restPath = "$mtsBaseUri/V1/Inventory?$queryParameters"
  $response = Invoke-RestMethod `
    -Method GET `
    -Uri $restPath `
    -Headers @{
    "MS-CV"         = $cv
    "Authorization" = "Bearer $($token.AccessToken)"
  }
  $productDictionary = @{}

  $productList = @($response.inventoryEntries | % {$_.productKey.productId}) -join ","

  $mDollarQueryParameters = Get-QueryString ([ordered]@{
      bigIds         = $productList
      market         = "US"
      languages      = "en-us"
      catalogId      = "4"
      fieldsTemplate = "Details"
    })

  $mDollarRestPath = "$mDollarBaseUri/v7.0/products?$mDollarQueryParameters"
  $mDollarContinuationToken = $null
    

  do {
    $mDollarresponse = Invoke-RestMethod `
      -Method GET `
      -Uri $mDollarRestPath `
      -Headers @{
      "MS-CV"         = $cv
      "Authorization" = "Bearer $($token.AccessToken)"
    }
    foreach ($product in $mDollarresponse.products) {
      $productDictionary.Add($product.productId, $product.LocalizedProperties.ProductTitle)
    }
    $mDollarContinuationToken = $result.ContinuationToken
  }while (-not ([String]::IsNullOrWhiteSpace($mDollarContinuationToken)))

  foreach ($inventoryEntry in $response.inventoryEntries) {
    New-Object PSObject -Property @{
    ProductTitle = $productDictionary[$inventoryEntry.productKey.productId]
    ProductId = $inventoryEntry.productKey.productId
    SkuId = $inventoryEntry.productKey.skuId
    LicenseType = $inventoryEntry.licenseType    
	}
  }
}

function Get-QueryString {
  param(
    [System.Collections.Specialized.OrderedDictionary]$Parameters
  )

  if ($Parameters) {
    @($Parameters.GetEnumerator() | ForEach-Object { $_.Name + '=' + $_.Value }) -join '&'
  }
}


function Get-MSStoreSeatAssignments() {
  [CmdletBinding(DefaultParameterSetName = "Batch")]
  param(
    [Parameter(Mandatory = $true)]
    [string] $ProductId,
    [Parameter(Mandatory = $true)]
    [string] $SkuId, 
    [Parameter(ParameterSetName = "Batch")]
    [ValidateRange(1, 25)]
    [int]$PageSize = 25
  )

  $continuationToken = $null    
    
  do {
    $result = Get-MtsSeatAssignmentsInternal `
      -ProductId $ProductId `
      -SkuId $SkuId `
      -MaxPageSize $PageSize `
      -ContinuationToken $continuationToken `
      -SessionState $PSCmdlet.SessionState

    Write-Output $result.Seats

    $continuationToken = $result.ContinuationToken
  }
  while (-not ([String]::IsNullOrWhiteSpace($continuationToken)))
}


<#
    .SYNOPSIS
    Method to retrieve Seat Assignment details
#>
function Get-MSStoreSeatAssignmentsInternal() {
  [CmdletBinding(DefaultParameterSetName = "Base")]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ProductId,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SkuId ,
    [Parameter(ParameterSetName = "Base")]
    [string] $ContinuationToken,
    [Parameter(ParameterSetName = "Base")]
    [int] $MaxPageSize = 25
  )

  Get-MtsSeatAssignmentsInternal `
    -ProductId $ProductId `
    -SkuId $SkuId `
    -ContinuationToken $ContinuationToken `
    -MaxPageSize $MaxPageSize `
    -SessionState $PSCmdlet.SessionState     
}

function Get-MtsSeatAssignmentsInternal() {
  [CmdletBinding(DefaultParameterSetName = "Base")]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ProductId,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SkuId ,
    [Parameter(ParameterSetName = "Base")]
    [string] $ContinuationToken,
    [Parameter(ParameterSetName = "Base")]
    [int] $MaxPageSize = 25,
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.SessionState]
    $SessionState

  )

  $token = Get-AccessTokenFromSessionData -SessionState $SessionState
  $cv = New-CV
  $mtsBaseUri = Get-MSStoreBaseUri -SessionState $SessionState

  $queryParameters = ""

  if (-not [String]::IsNullOrWhiteSpace($ContinuationToken)) {
    $queryParameters += "continuationtoken=$($ContinuationToken)&"
  }

  if ($MaxPageSize -ne $null) {
    $queryParameters += "maxResults=$($MaxPageSize)&"
  }

  # get rid of any trailing ampersands
  $queryParameters = $queryParameters.TrimEnd("&");

  $restPath = "$mtsBaseUri/V1/Inventory/$($ProductId)/$($SkuId)/Seats?$($queryParameters)"
    
  $response = Invoke-RestMethod `
    -Method GET `
    -Uri $restPath `
    -Headers @{
    "MS-CV"         = $cv
    "Authorization" = "Bearer $($token.AccessToken)"
  } 
            
  $response
}


<#
    .SYNOPSIS
    Method to assign seats to a user
#>
function Add-MSStoreSeatAssignment() {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Username,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ProductId,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SkuId 
  )

  $token = Get-AccessTokenFromSessionData -SessionState $PSCmdlet.SessionState
  $cv = New-CV
  $mtsBaseUri = Get-MSStoreBaseUri -SessionState $PSCmdlet.SessionState
    
  $restPath = "$mtsBaseUri/V1/Inventory/$($ProductId)/$($SkuId)/Seats/$($Username)"
  $response = Invoke-RestMethod `
    -Method Post `
    -Uri $restPath `
    -Headers @{
    "MS-CV"         = $cv
    "Authorization" = "Bearer $($token.AccessToken)"
  } `
    -ContentType 'application/json'
            
  $response    

  Get-StoreInstallLink $ProductId $SkuId
}

<#
    .SYNOPSIS
    Method to remove seats assignments
#>
function Remove-MSStoreSeatAssignments() {
  [CmdletBinding(DefaultParameterSetName = "Usernames")]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ProductId,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SkuId,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 25)]
    [int] $BatchSize = 25,
    [Parameter(Mandatory = $true, ParameterSetName = "Usernames")]
    [string[]] $Usernames,
    [Parameter(Mandatory = $true, ParameterSetName = "Csv")]
    [ValidateNotNullOrEmpty()]
    [string] $PathToCsv,
    [Parameter(Mandatory = $false, ParameterSetName = "Csv")]
    [ValidateNotNullOrEmpty()]
    [string] $ColumnName = "Username",
    [switch] $ShowProgress

  )

  if ($PSCmdlet.ParameterSetName -eq "Usernames") {
    Start-MtsBulkSeatOperation `
      -Operation "reclaim" `
      -ProductId $ProductId `
      -SkuId $SkuId `
      -BatchSize $BatchSize `
      -Usernames $Usernames `
      -ShowProgress:$ShowProgress `
      -SessionState $PSCmdlet.SessionState
  }
  elseif ($PSCmdlet.ParameterSetName -eq "Csv") {
    Start-MtsBulkSeatOperation `
      -Operation "reclaim" `
      -ProductId $ProductId `
      -SkuId $SkuId `
      -BatchSize $BatchSize `
      -PathToCsv $PathToCsv `
      -ColumnName $ColumnName `
      -ShowProgress:$ShowProgress `
      -SessionState $PSCmdlet.SessionState
  }

}

<#
    .SYNOPSIS
    Method to assign seats to a user
#>
function Add-MSStoreSeatAssignments() {
  [CmdletBinding(DefaultParameterSetName = "Usernames")]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ProductId,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SkuId,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 25)]
    [int] $BatchSize = 25,
    [Parameter(Mandatory = $true, ParameterSetName = "Usernames")]
    [string[]] $Usernames,
    [Parameter(Mandatory = $true, ParameterSetName = "Csv")]
    [ValidateNotNullOrEmpty()]
    [string] $PathToCsv,
    [Parameter(Mandatory = $false, ParameterSetName = "Csv")]
    [ValidateNotNullOrEmpty()]
    [string] $ColumnName = "Username",
    [switch] $ShowProgress

  )

  if ($PSCmdlet.ParameterSetName -eq "Usernames") {
    Start-MtsBulkSeatOperation `
      -Operation "assign" `
      -ProductId $ProductId `
      -SkuId $SkuId `
      -BatchSize $BatchSize `
      -Usernames $Usernames `
      -ShowProgress:$ShowProgress `
      -SessionState $PSCmdlet.SessionState
  }
  elseif ($PSCmdlet.ParameterSetName -eq "Csv") {
    Start-MtsBulkSeatOperation `
      -Operation "assign" `
      -ProductId $ProductId `
      -SkuId $SkuId `
      -BatchSize $BatchSize `
      -PathToCsv $PathToCsv `
      -ColumnName $ColumnName `
      -ShowProgress:$ShowProgress `
      -SessionState $PSCmdlet.SessionState
  }

  Get-StoreInstallLink $ProductId $SkuId
}

function Start-MtsBulkSeatOperation() {
  [CmdletBinding(DefaultParameterSetName = "Usernames")]
  param(
    [Parameter(Mandatory = $true)]
    [string] $Operation,
    [Parameter(Mandatory = $true)]
    [string] $ProductId,
    [Parameter(Mandatory = $true)]
    [string] $SkuId,
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 25)]
    [int] $BatchSize = 25,
    [Parameter(Mandatory = $true, ParameterSetName = "Usernames")]
    [string[]] $Usernames,
    [Parameter(Mandatory = $true, ParameterSetName = "Csv")]
    [ValidateNotNullOrEmpty()]
    [string] $PathToCsv,
    [Parameter(Mandatory = $false, ParameterSetName = "Csv")]
    [ValidateNotNullOrEmpty()]
    [string] $ColumnName = "Username",
    [switch] $ShowProgress,
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.SessionState]
    $SessionState

  )

  process { 
    $_enforceSingleCall = $false

    $usernamesToProcess = $null

    if ($PSCmdlet.ParameterSetName -eq "Usernames") {
      if ($Usernames -eq $null -or $Usernames.Length -eq 0) {
        throw "At least one username must be specified in the Usernames parameter"
      }
            
      if ($_enforceSingleCall -and $Usernames.Length -gt 25) {
        throw "The maximum number of assignments in one call is 25."
      }
            

      $usernamesToProcess = [string[]] ($Usernames | ? {-not [String]::IsNullOrWhiteSpace($_)})
    }
    elseif ($PSCmdlet.ParameterSetName -eq "Csv") {
      $inputData = Import-Csv -Path $PathToCsv

      $usernamesToProcess = [string[]] ($inputData | % { $_.$ColumnName})


      # read the Csv

      # take only entries which have a "Username" column in them
    }
       

    $processedItemCount = 0;

    while ($processedItemCount -lt $usernamesToProcess.Length) {
      if ($ShowProgress) {
        Write-Progress  -Activity "Bulk Operation" -Status "Percent complete:"  -PercentComplete (($processedItemCount / $usernamesToProcess.Length) * 100)
      }

      $currentBatch = [string[]]($usernamesToProcess | select-object -Skip $processedItemCount -First $BatchSize)

      # get a new token on each "batch" to ensure it's not expired
      $token = Get-AccessTokenFromSessionData -SessionState $SessionState

      $cv = New-CV

      $mtsBaseUri = Get-MSStoreBaseUri -SessionState $SessionState

      $body = @{
        usernames  = $currentBatch
        seatAction = $Operation
      }
            
      $restPath = "$mtsBaseUri/V1/Inventory/$($ProductId)/$($SkuId)/Seats"

      $response = Invoke-RestMethod `
        -Method Post `
        -Uri $restPath `
        -Headers @{
        "MS-CV"         = $cv
        "Authorization" = "Bearer $($token.AccessToken)"
      } `
        -Body ($body | ConvertTo-Json) `
        -ContentType 'application/json'

      # process bulk response into individual items
      $successfulAssignments = [object[]]$response.SeatDetails
      $failedAssignments = [object[]]$response.FailedSeatOperations

      if ($successfulAssignments -ne $null) {
        foreach ($successfulAssignment in $successfulAssignments) {
          Write-Output (New-Object psobject($successfulAssignment) -Property @{
              Result = "Succeeded"
            })
        }
      }

      if ($failedAssignments -ne $null) {
        foreach ($failedAssignment in $failedAssignments) {
          Write-Output (New-Object psobject($failedAssignment) -Property @{
              Result = "Failed"
            })
        }
      }

      $processedItemCount += $currentBatch.Length  

      if ($ShowProgress) {
        Write-Progress  -Activity "Bulk Operation" -Status "Percent complete:"  -PercentComplete (($processedItemCount / $usernamesToProcess.Length) * 100)
      }
    }
  }  
}


function Remove-MSStoreSeatAssignmentsLegacy() {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateCount(1, 25)]
    [string[]] $Usernames,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ProductId,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SkuId 
  )

  $token = Get-AccessTokenFromSessionData -SessionState $PSCmdlet.SessionState
  $cv = New-CV
  $mtsBaseUri = Get-MSStoreBaseUri -SessionState $PSCmdlet.SessionState

  $body = @{
    usernames  = $Usernames
    seatAction = "reclaim"
  }
    
  $restPath = "$mtsBaseUri/V1/Inventory/$($ProductId)/$($SkuId)/Seats"
  $response = Invoke-RestMethod `
    -Method Post `
    -Uri $restPath `
    -Headers @{
    "MS-CV"         = $cv
    "Authorization" = "Bearer $($token.AccessToken)"
  } `
    -Body ($body | ConvertTo-Json) `
    -ContentType 'application/json'
            
  $response
}

<#
    .SYNOPSIS
    Method to remove seats assigned to a user
#>
function Remove-MSStoreSeatAssignment() {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Username,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ProductId,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SkuId 
  )

  $token = Get-AccessTokenFromSessionData -SessionState $PSCmdlet.SessionState
  $cv = New-CV
  $mtsBaseUri = Get-MSStoreBaseUri -SessionState $PSCmdlet.SessionState
    
  $restPath = "$mtsBaseUri/V1/Inventory/$($ProductId)/$($SkuId)/Seats/$($Username)"

  $response = Invoke-RestMethod `
    -Method Delete `
    -Uri $restPath `
    -Headers @{
    "MS-CV"         = $cv
    "Authorization" = "Bearer $($token.AccessToken)"
  } 

  $response 
}

<#
    .SYNOPSIS
    Method to retrieve install link for given product and sku
#>
function Get-StoreInstallLink() {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ProductId,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SkuId 
  )
  write-host "You can provide this URL to your users in order to install this app from the store:"

  $installLink = "https://businessstore.microsoft.com/en-us/AppInstall?productId=" + $ProductId + "&skuId=" + $SkuId + "&catalogId=4"
  write-host $installLink `n`n
}


################################
# End: Exported functions
################################

Write-Host "MSStore module loaded"

# SIG # Begin signature block
# MIIkVwYJKoZIhvcNAQcCoIIkSDCCJEQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBbkz+TOsOZAHLC
# 6/jyZ7/boJaNQzH0WHxYK3A00rUHeqCCDZMwggYRMIID+aADAgECAhMzAAAAjoeR
# pFcaX8o+AAAAAACOMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMTYxMTE3MjIwOTIxWhcNMTgwMjE3MjIwOTIxWjCBgzEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjENMAsGA1UECxMETU9Q
# UjEeMBwGA1UEAxMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEA0IfUQit+ndnGetSiw+MVktJTnZUXyVI2+lS/qxCv
# 6cnnzCZTw8Jzv23WAOUA3OlqZzQw9hYXtAGllXyLuaQs5os7efYjDHmP81LfQAEc
# wsYDnetZz3Pp2HE5m/DOJVkt0slbCu9+1jIOXXQSBOyeBFOmawJn+E1Zi3fgKyHg
# 78CkRRLPA3sDxjnD1CLcVVx3Qv+csuVVZ2i6LXZqf2ZTR9VHCsw43o17lxl9gtAm
# +KWO5aHwXmQQ5PnrJ8by4AjQDfJnwNjyL/uJ2hX5rg8+AJcH0Qs+cNR3q3J4QZgH
# uBfMorFf7L3zUGej15Tw0otVj1OmlZPmsmbPyTdo5GPHzwIDAQABo4IBgDCCAXww
# HwYDVR0lBBgwFgYKKwYBBAGCN0wIAQYIKwYBBQUHAwMwHQYDVR0OBBYEFKvI1u2y
# FdKqjvHM7Ww490VK0Iq7MFIGA1UdEQRLMEmkRzBFMQ0wCwYDVQQLEwRNT1BSMTQw
# MgYDVQQFEysyMzAwMTIrYjA1MGM2ZTctNzY0MS00NDFmLWJjNGEtNDM0ODFlNDE1
# ZDA4MB8GA1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0Nv
# ZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsG
# AQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01p
# Y0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkq
# hkiG9w0BAQsFAAOCAgEARIkCrGlT88S2u9SMYFPnymyoSWlmvqWaQZk62J3SVwJR
# avq/m5bbpiZ9CVbo3O0ldXqlR1KoHksWU/PuD5rDBJUpwYKEpFYx/KCKkZW1v1rO
# qQEfZEah5srx13R7v5IIUV58MwJeUTub5dguXwJMCZwaQ9px7eTZ56LadCwXreUM
# tRj1VAnUvhxzzSB7pPrI29jbOq76kMWjvZVlrkYtVylY1pLwbNpj8Y8zon44dl7d
# 8zXtrJo7YoHQThl8SHywC484zC281TllqZXBA+KSybmr0lcKqtxSCy5WJ6PimJdX
# jrypWW4kko6C4glzgtk1g8yff9EEjoi44pqDWLDUmuYx+pRHjn2m4k5589jTajMW
# UHDxQruYCen/zJVVWwi/klKoCMTx6PH/QNf5mjad/bqQhdJVPlCtRh/vJQy4njpI
# BGPveJiiXQMNAtjcIKvmVrXe7xZmw9dVgh5PgnjJnlQaEGC3F6tAE5GusBnBmjOd
# 7jJyzWXMT0aYLQ9RYB58+/7b6Ad5B/ehMzj+CZrbj3u2Or2FhrjMvH0BMLd7Hald
# G73MTRf3bkcz1UDfasouUbi1uc/DBNM75ePpEIzrp7repC4zaikvFErqHsEiODUF
# he/CBAANa8HYlhRIFa9+UrC4YMRStUqCt4UqAEkqJoMnWkHevdVmSbwLnHhwCbww
# ggd6MIIFYqADAgECAgphDpDSAAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3Nv
# ZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5
# MDlaFw0yNjA3MDgyMTA5MDlaMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIw
# MTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQ
# TTS68rZYIZ9CGypr6VpQqrgGOBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULT
# iQ15ZId+lGAkbK+eSZzpaF7S35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYS
# L+erCFDPs0S3XdjELgN1q2jzy23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494H
# DdVceaVJKecNvqATd76UPe/74ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZ
# PrGMXeiJT4Qa8qEvWeSQOy2uM1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5
# bmR/U7qcD60ZI4TL9LoDho33X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGS
# rhwjp6lm7GEfauEoSZ1fiOIlXdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADh
# vKwCgl/bwBWzvRvUVUvnOaEP6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON
# 7E1JMKerjt/sW5+v/N2wZuLBl4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xc
# v3coKPHtbcMojyyPQDdPweGFRInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqw
# iBfenk70lrC8RqBsmNLg1oiMCwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMC
# AQAwHQYDVR0OBBYEFEhuZOVQBdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQM
# HgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1Ud
# IwQYMBaAFHItOgIxkEO5FAVO4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0
# dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0Nl
# ckF1dDIwMTFfMjAxMV8wM18yMi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUF
# BzAChkJodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0Nl
# ckF1dDIwMTFfMjAxMV8wM18yMi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGC
# Ny4DMIGDMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2RvY3MvcHJpbWFyeWNwcy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcA
# YQBsAF8AcABvAGwAaQBjAHkAXwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZI
# hvcNAQELBQADggIBAGfyhqWY4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4s
# PvjDctFtg/6+P+gKyju/R6mj82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKL
# UtCw/WvjPgcuKZvmPRul1LUdd5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7
# pKkFDJvtaPpoLpWgKj8qa1hJYx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft
# 0N3zDq+ZKJeYTQ49C/IIidYfwzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4
# MnEnGn+x9Cf43iw6IGmYslmJaG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxv
# FX1Fp3blQCplo8NdUmKGwx1jNpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG
# 0QaxdR8UvmFhtfDcxhsEvt9Bxw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf
# 0AApxbGbpT9Fdx41xtKiop96eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkY
# S//WsyNodeav+vyL6wuA6mk7r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrv
# QQqxP/uozKRdwaGIm1dxVk5IRcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIW
# GjCCFhYCAQEwgZUwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEoMCYGA1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAA
# AI6HkaRXGl/KPgAAAAAAjjANBglghkgBZQMEAgEFAKCCAQcwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJ
# KoZIhvcNAQkEMSIEIJySPJigBXLwjtp3qUXM7NcyVcJOmC0zB2InxIoRR+TvMIGa
# BgorBgEEAYI3AgEMMYGLMIGIoF6AXABNAGkAYwByAG8AcwBvAGYAdAAgAFMAdABv
# AHIAZQAgAGYAbwByACAAQgB1AHMAaQBuAGUAcwBzACAAUABvAHcAZQByAFMAaABl
# AGwAbAAgAG0AbwBkAHUAbABloSaAJGh0dHBzOi8vYnVzaW5lc3NzdG9yZS5taWNy
# b3NvZnQuY29tIDANBgkqhkiG9w0BAQEFAASCAQCWpPspADgxw6mfY36DsbaexZDf
# 698jWZJjL8lX+HOjBdGlyR5LkDAO2OxNFk9Btzi4N3yH6DDy5qLXeMGXhKYwR2UG
# qkwPH7UTcX7oHBr2uCplVpPxGlzuGNUQkKSn0Z60CJ6aBYJ0d+DQ5E/SSWBxdxjL
# dvcsarRzx0PXhLDxqN4IUExQLA456fByHJkGRk8uqrtXcIppVOcv+IE2ox/EouU6
# whG198aybepGfCgN4u3dyDtR5dowCDdsWkSLP6O4wK/ql9SVZEGQk5JDnd8c9bw+
# roGOyvFucTWDUscJc7J2o3x4nUst8/hDlNGohebURxKaf0uDpZUf/AFuGWFjoYIT
# SjCCE0YGCisGAQQBgjcDAwExghM2MIITMgYJKoZIhvcNAQcCoIITIzCCEx8CAQMx
# DzANBglghkgBZQMEAgEFADCCAT0GCyqGSIb3DQEJEAEEoIIBLASCASgwggEkAgEB
# BgorBgEEAYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIDQEJx4ObfpU+6tVFbj9skTU
# bYVEGcPG4Iffch2fH4elAgZZelNloJsYEzIwMTcwODAxMTMzMTMyLjE0NlowBwIB
# AYACAfSggbmkgbYwgbMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xDTALBgNVBAsTBE1PUFIxJzAlBgNVBAsTHm5DaXBoZXIgRFNFIEVTTjpDMEY0
# LTMwODYtREVGODElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZaCCDs0wggZxMIIEWaADAgECAgphCYEqAAAAAAACMA0GCSqGSIb3DQEBCwUAMIGI
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylN
# aWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0xMDA3
# MDEyMTM2NTVaFw0yNTA3MDEyMTQ2NTVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqR0NvHcRijog
# 7PwTl/X6f2mUa3RUENWlCgCChfvtfGhLLF/Fw+Vhwna3PmYrW/AVUycEMR9BGxqV
# Hc4JE458YTBZsTBED/FgiIRUQwzXTbg4CLNC3ZOs1nMwVyaCo0UN0Or1R4HNvyRg
# MlhgRvJYR4YyhB50YWeRX4FUsc+TTJLBxKZd0WETbijGGvmGgLvfYfxGwScdJGcS
# chohiq9LZIlQYrFd/XcfPfBXday9ikJNQFHRD5wGPmd/9WbAA5ZEfu/QS/1u5ZrK
# sajyeioKMfDaTgaRtogINeh4HLDpmc085y9Euqf03GS9pAHBIAmTeM38vMDJRF1e
# FpwBBU8iTQIDAQABo4IB5jCCAeIwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYE
# FNVjOlyKMZDzQ3t8RhvFM2hahW1VMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBB
# MAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP
# 6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWlj
# cm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2
# LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMu
# Y3J0MIGgBgNVHSABAf8EgZUwgZIwgY8GCSsGAQQBgjcuAzCBgTA9BggrBgEFBQcC
# ARYxaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL1BLSS9kb2NzL0NQUy9kZWZhdWx0
# Lmh0bTBABggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBQAG8AbABpAGMAeQBf
# AFMAdABhAHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAB+aIUQ3i
# xuCYP4FxAz2do6Ehb7Prpsz1Mb7PBeKp/vpXbRkws8LFZslq3/Xn8Hi9x6ieJeP5
# vO1rVFcIK1GCRBL7uVOMzPRgEop2zEBAQZvcXBf/XPleFzWYJFZLdO9CEMivv3/G
# f/I3fVo/HPKZeUqRUgCvOA8X9S95gWXZqbVr5MfO9sp6AG9LMEQkIjzP7QOllo9Z
# Kby2/QThcJ8ySif9Va8v/rbljjO7Yl+a21dA6fHOmWaQjP9qYn/dxUoLkSbiOewZ
# SnFjnXshbcOco6I8+n99lmqQeKZt0uGc+R38ONiU9MalCpaGpL2eGq4EQoO4tYCb
# IjggtSXlZOz39L9+Y1klD3ouOVd2onGqBooPiRa6YacRy5rYDkeagMXQzafQ732D
# 8OE7cQnfXXSYIghh2rBQHm+98eEA3+cxB6STOvdlR3jo+KhIq/fecn5ha293qYHL
# pwmsObvsxsvYgrRyzR30uIUBHoD7G4kqVDmyW9rIDVWZeodzOwjmmC3qjeAzLhIp
# 9cAvVCch98isTtoouLGp25ayp0Kiyc8ZQU3ghvkqmqMRZjDTu3QyS99je/WZii8b
# xyGvWbWu3EQ8l1Bx16HSxVXjad5XwdHeMMD9zOZN+w2/XU/pnR4ZOC+8z1gFLu8N
# oFA12u8JJxzVs341Hgi62jbb01+P3nSISRIwggTaMIIDwqADAgECAhMzAAAAo+8f
# IiCBY9ylAAAAAACjMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMB4XDTE2MDkwNzE3NTY0OVoXDTE4MDkwNzE3NTY0OVowgbMxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1PUFIx
# JzAlBgNVBAsTHm5DaXBoZXIgRFNFIEVTTjpDMEY0LTMwODYtREVGODElMCMGA1UE
# AxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAKnRHpfHE2n4ODsVF+ZIDvlfgqxUnTAarRBd0PIF9z9o
# hjda0ABT5pxtHGjyKcfW/zGYUk0RuvXBZIY6OQknVklen6EhGSkbzFoW4/N9AVUX
# LOnhrJb7x5mvKHAAdSL6LnKUVF+60cWsMtTl1h558IGjCr5jvnhpZ+KPhdHJvsh/
# kIvkuH6Yrm++KmQIGki3OSHIavQkS2AQ1HKAcgg46W75O1PtWdsk1E1hyFvTaWMA
# Mr3MsVE960C4f7i+u3IdwThs3gmObi2ZOmxFCN6zT1ttbYCR2SObSJlMHuURf7MX
# nnaRveImFh8RABw635noLP/sdSxYKXCnFy0o7o+0o18CAwEAAaOCARswggEXMB0G
# A1UdDgQWBBT6hbpmZuhGmdpwn7ohJUDb4OixcDAfBgNVHSMEGDAWgBTVYzpcijGQ
# 80N7fEYbxTNoWoVtVTBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNUaW1TdGFQQ0FfMjAxMC0wNy0w
# MS5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1RpbVN0YVBDQV8yMDEwLTA3LTAxLmNy
# dDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEB
# CwUAA4IBAQAd0UW6W7S/iuaGjUXONYgmEkawM4NqYTHIFnP45iR6asHAFTc8jccp
# DUjLdJelsofhBnjVQ4xTOvDiUQ54ttP8HI0l5VMaFdk+erzHu8FOZlhRGA9lJWEh
# ob7mkcNgjvkJtD6IwqZygTsc8hAc1QWuiF00VVKoQ4aM8A1UvkvkS+4XlbabvAJr
# Fs2yLWz1q9814QaDtFlB5x4B82hN99jeJCxGS0LAjRdzRFArjd52zX90Xd/mZMwy
# uJ7Az2VSEQgGepe2g2WjYtjDg7o5jke4U6rDZhocvUlO9NzUB6zSuNFk+eB3yex2
# gMSrFyvrI4O1lonx2EuWkt1vqcI71vOcoYIDdjCCAl4CAQEwgeOhgbmkgbYwgbMx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1P
# UFIxJzAlBgNVBAsTHm5DaXBoZXIgRFNFIEVTTjpDMEY0LTMwODYtREVGODElMCMG
# A1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIlCgEBMAkGBSsOAwIa
# BQADFQA15KP7Tj//Jg1x9W1eEnuRljimjaCBwjCBv6SBvDCBuTELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjENMAsGA1UECxMETU9QUjEnMCUGA1UE
# CxMebkNpcGhlciBOVFMgRVNOOjRERTktMEM1RS0zRTA5MSswKQYDVQQDEyJNaWNy
# b3NvZnQgVGltZSBTb3VyY2UgTWFzdGVyIENsb2NrMA0GCSqGSIb3DQEBBQUAAgUA
# 3SrDBjAiGA8yMDE3MDgwMTA5MDYxNFoYDzIwMTcwODAyMDkwNjE0WjB0MDoGCisG
# AQQBhFkKBAExLDAqMAoCBQDdKsMGAgEAMAcCAQACAjmSMAcCAQACAhkUMAoCBQDd
# LBSGAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwGgCjAIAgEAAgMW
# 42ChCjAIAgEAAgMHoSAwDQYJKoZIhvcNAQEFBQADggEBAHU5OA/4L4u9nxRcS+Dm
# gifNaT5/R+PqG8tp08Oi7elVdN5ViaFBROnpY3k2LC0ISZTMXHiiyl4FvjcsjXlz
# 6H/SiURpKabyDBxCcK/H0LJLmOgu5rALbJsD7bNcJ+O7su6iJku8VYNFe9b4AB5m
# 1t6bihz1/dCwNY/a++QcNWxruz3VQLud+iBxXf6V5Pu317H4I4Bhnhn8hS5YTa+s
# n4E3vWZN3UuWezDlOSSao5naGTXs9vBcAY9NtEGtlKYam5pzTEjWferVxkfwUiZo
# FcnRAAJZ1K4BsQNU0PEhKLPK3M1V3mmNZtLPHgzRIwqny2Co3YotZ2ZYzH/9Yrzw
# 6gwxggL1MIIC8QIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAIT
# MwAAAKPvHyIggWPcpQAAAAAAozANBglghkgBZQMEAgEFAKCCATIwGgYJKoZIhvcN
# AQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCDnzklYOniYpYeosZDG
# 4YpWGh1Ecz/USt1YqJVHfpC9DDCB4gYLKoZIhvcNAQkQAgwxgdIwgc8wgcwwgbEE
# FDXko/tOP/8mDXH1bV4Se5GWOKaNMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTACEzMAAACj7x8iIIFj3KUAAAAAAKMwFgQUfqYwrgG+WdpDCIXP
# a1KHEKr64XYwDQYJKoZIhvcNAQELBQAEggEAguFmiVtjqGQLt/EmSlW0kXCdZFSN
# 33e4oiC2Qmuhj9ayEppqPyE6RuMkBjELj/iZxPow+/7qds8N97KJ25Jp9F4YQt62
# iRNfRII9cGeoEkX5KTDWzDrsohlQCRELzfe87iAvF+dEoshtnAVPuoc8O2rVt8kg
# rL9Y9YMphq89MmlmNkzvwBrfCAvYQD1SMddyIpDSm2ZrQjFpiFnnZHuEC7yM8A66
# hNHb/2Nkufjw7Nku3zekyhH7VfHUUAMIK2VcIFRxU17LbwLEzykv3yIqK0gzCjNp
# xFN3GXa4OcLCPqLILw0kSfyYfZB0Njkkq4Wzj/mLnNJTL7e1KfJJxxjhhQ==
# SIG # End signature block
