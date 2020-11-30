# Season of Serverless

Welcome to my repository with my solutions to the initiative https://github.com/microsoft/Seasons-of-Serverless.

Participants receive a new delicious challenge every week, in which you're challenged to solve a puzzle/problem with an Azure Function.

This repository holds my solutions (Azure Function code in PowerShell) for the problems.

To help other with their problems, I'll show how I solved this with the approach I took. 

## Week 1

### Usage

PowerShell POST
```ps
$param = @{
URI = 'https://deliciousturkeyrecipeshoppinglist.azurewebsites.net/api/DeliciousTurkeyRecipe'
# replace your turkeyweight here
Body = (@{Weight=5}| ConvertTo-Json)
Method = 'Post'
ContentType = 'application/json'
}
Invoke-Restmethod @param
``` 


```
$param = @{
# You can enter the weight behind `=` in the URI, to supply the function with the weight of your turkey.
URI = 'https://deliciousturkeyrecipeshoppinglist.azurewebsites.net/api/DeliciousTurkeyRecipe?Weight=5'
Method = 'Get'
}
Invoke-Restmethod @param
```

### Solution

https://github.com/microsoft/Seasons-of-Serverless/blob/main/Nov-23-2020.md

In this challenge we received the follow instructions:

```
Your challenge 🍽

Convert this brine equation and cook time to an automated process so that when you input a turkey's weight, you will be given the amount of water, sugar, salt, and spices to add and a recommendation on how long to cook it.

Let's assume you have available a large cooler for your turkey and its brine and that it's defrosted.

Our chefs recommends trying an Azure Function to generate your recipe, and encourages you to share your own turkey secrets by adding a link to your solution in the Issues tab!

Brine Instructions

    Salt (in cups) = 0.05 * lbs of turkey
    Water (gallons) = 0.66 * lbs of turkey
    Brown sugar (cups) = 0.13 * lbs of turkey
    Shallots = 0.2 * lbs of turkey
    Cloves of garlic = 0.4 * lbs of turkey
    Whole peppercorns (tablespoons) = 0.13 * lbs of turkey
    Dried juniper berries (tablespoons) = 0.13 * lbs of turkey
    Fresh rosemary (tablespoons) = 0.13 * lbs of turkey
    Thyme (tablespoons) = 0.06 * lbs of turkey
    Brine time (in hours) = 2.4 * lbs of turkey
    Roast time (in minutes) = 15 * lbs of turkey
```

In this instruction some things are relevant to us:

1. The chefs want us to use an Azure Function to solve the challenge;
2. The end-result should be a converted list, which contains the ingredients and duration in time (all of which are dependant on the `weight` of the turkey).
3. We need the chef to be able to supply the weight of a turkey in lbs. to calculate the ingredients and actions.

Functions work based on triggers, so we should create a function logic, which accepts the cook' input (weight of the turkey in lbs.), calculates and outputs the relevant information. 

## Let's get started.

To get started I used Visual Studio Code and the Azure Extension.
This extension has a nice functionality that I can create, test and deploy Azure Functions, written in: C#, Java, JavaScript, PowerShell, Python or Typescript; all throught the GUI, without having to do multiple steps by myself. Because remember an Azure Function is similar to a web-app, it's contained within an Azure App Service Plan, and logs should be transferred and analyzed with Application Insights. Luckily the extension deploys all of these for you. For more information see (https://docs.microsoft.com/en-us/azure/azure-functions/create-first-function-vs-code-powershell#create-an-azure-functions-project)


So I took the following steps to create a function:

1. Create a new project, here you'll choose a folder path

Mind that the Azure extension deploys all of the necessary things that you need for the function to work. So this is the root of your function-app (containing one or multiple functions).

2. Choose a language (I chose PowerShell)
3. Choose a Trigger (I chose HTTP trigger)

To keep it simple (best approach to Azure Functions) I chose the HTTP-trigger input binding. This means that the weight should be sent to the function using HTTP web requests. In PowerShell you can use Invoke-WebRequest or Invoke-RestMethod (for REST-API's). In Azure Functions you only have 1 output (also referred to as the output-binding), in which you output your function-code output. In this case we need to convert information using one common factor (the turkey' weight) to a list containing multiple calculated properties. So I think a JSON-body would be the easiest to output.

I am by no means a coding professional, so I chose PowerShell to keep it even more simple.

4. Enter a function name
5. Choose the authorization scope of the function (for more info read: https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger#authorization-keys)

After we did this we have a functional function template which can already be tested, In Visual Studio Code you can test your function locally.
It created multiple files, but we're mainly interested in the folder which contains the run.ps1.

This run.ps1 template contains a function which returns the name if you've supplied it with your webrequest.
So after you've pressed F5, your Visual Studio Code behaves like your function would in a Function App on Azure (nice!), no more testing in production.

The template function has a few interesting parts we can re-use, which are already commented by the creator of the template:


```ps
using namespace System.Net

# Input bindings are passed in via param block. (This is where our weight will arrive)
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream. (We can output our progress in our script, this is handy when debugging!)
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request. (This switches between the HTTP query string and the JSON body with a web request)
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}

# Associate values to output bindings by calling 'Push-OutputBinding'. (We'll re-use this to output our end-result and bad requests)
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
```

## Writing PowerShell

The template is an awesome start, but we lack a few things:

* We have no way to check if it's a number (weight is represented by an integer)
* The user needs to know if the function triggered and when they supplied an invalid value for $weight
* We need a format in which we can calculate all the things the chef needs, and display it to the chef.

I rewrote it to this:
```ps
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$weight = $Request.Query.Weight
if (-not $weight) {
    $weight = $Request.Body.Weight
}


# I need to be sure my $weight is a number, else multiplication will be non-sense. 
# I used the TryParse, there are many ways to do this. Usually you validate this in your param block.
# We want to make sure we have something we can multiply our ingredients with as a weight factor. 
# In case we don't have that we need to make sure the chef knows this and knows what to do.

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

# The ingredients in this recipe all share the same property in that their measures are defined by their relation to the weight of the turkey.
# So if we build simple  logic, we can reuse that and focus on the differences. 
# I created a hashtable to contain our ingredients, this easily converts to the JSON-object we need to output.
# In each line I created a key for our hashtable with the name of the ingredient, the value of this key is a string (of text) which is calculated with the weight.
# By using sub-expression (https://ss64.com/ps/syntax-operators.html) we can calculate the ingredient before outputting it

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

# We need to output our JSON-object so the chef knows how big of a shopping bag they need and how much time they need to reserve to code the next challenge!

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })
``` 
