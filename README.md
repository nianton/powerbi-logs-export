# Power BI Audit Logs Export

This is a solution to export Power BI Logs to an Azure Storage Account via leveraging Azure Functions and the respective PowerShell modules. It contains the Infrastrure-as-Code implementation in bicel to deploy all the necessary resources, as well as, a sample time-triggered Azure Function to export the logs as CSV files to a targeted Azure Storage Account.

The main deployment is handled by the **`main.bicep`** file, which dictates the resources to be created within the created resource group and is responsible to consume the naming module as input.