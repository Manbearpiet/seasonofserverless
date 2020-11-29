using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$weight = $Request.Query.Weight
if (-not $weight) {
    $weight = $Request.Body.Weight
}

$parsedweight = 0
if ($weight -is "Int32" -or $weight -is "Double") {
    Write-Host "Already an Integer"
} elseif ([Decimal]::TryParse($weight, [Globalization.NumberStyles]::Float, (Get-Culture), [ref]$parsedweight)) {
    $weight = $parsedweight
} else {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = "🦃: This HTTP triggered function executed successfully. Pass a valid weight of turkey in the query string or in the request body for a personalized recipe."
            | ConvertTo-Json
        })
    exit
}

$body = @{
    "Salt"                  = "$(0.05 * $weight) cups"
    "Water"                 = "$(0.66 * $weight) gallons"
    "Brown sugar "          = "$(0.13 * $weight) cups"
    "Shallots"              = "$(0.2 * $weight) shallots"
    "Cloves of garlic"      = "$(0.4 * $weight) cloves"
    "Whole peppercorns"     = "$(0.13 * $weight) tablespoons"
    "Dried juniper berries" = "$(0.13 * $weight) tablespoons"
    "Fresh rosemary"        = "$(0.13 * $weight) tablespoons"
    "Thyme"                 = "$(0.06 * $weight) tablespoons "
    "Brine time"            = "$(2.4 * $weight) hours"
    "Roast time"            = "$(15 * $weight) minutes"
} | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })
