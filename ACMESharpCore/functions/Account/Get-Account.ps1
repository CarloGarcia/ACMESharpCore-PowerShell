function Get-Account {
    <#
    #>
    [CmdletBinding(DefaultParameterSetName = "FindAccount")]
    param(
        [Parameter(Position = 0, ParameterSetName="FindAccount")]
        [ValidateNotNull()]
        [AcmeDirectory]
        $Directory = $Script:ServiceDirectory,

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName="GetAccount")]
        [ValidateNotNull()]
        [uri] $AccountUrl, 

        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [IAccountKey] $AccountKey = $Script:AccountKey,

        [Parameter(Position = 2, ParameterSetName="GetAccount")]
        [ValidateNotNullOrEmpty()]
        [string] $KeyId = $Script:KeyId,

        [Parameter(Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $Nonce = $Script:Nonce,

        [Parameter()]
        [switch]
        $AutomaticAccountHandling
    )

    if($PSCmdlet.ParameterSetName -eq "FindAccount") {
        $payload = @{"onlyReturnExisting" = $true};

        $requestBody = New-SignedMessage -Url $Directory.NewAccount -Payload $payload -AccountKey $AccountKey -Nonce $Nonce
        $response = Invoke-AcmeWebRequest $Directory.NewAccount $requestBody -Method POST
    
        if($response.StatusCode -eq 200) {
            $Nonce = $response.NextNonce;
            $KeyId = $response.Headers["Location"][0];
            
            $AccountUrl = $KeyId;
        } else {
            Write-Error "JWK seems not to be registered for an account."
            return $null;
        }
    } 

    $requestBody = New-SignedMessage -Url $AccountUrl -Payload @{} -AccountKey $AccountKey -KeyId $KeyId -Nonce $Nonce

    $response = Invoke-AcmeWebRequest $AccountUrl -Method POST -JsonBody $requestBody
    $result = [AcmeAccount]::new($response, $KeyId);

    if($AutomaticAccountHandling) {
        Enable-AccountHandling -Account $result;
    }

    return $result;
}