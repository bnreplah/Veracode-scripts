# Read input JSON file
$inputJson = Get-Content -Raw -Path "results.json" | ConvertFrom-Json

# Convert JSON to SARIF format
$sarifOutput = @{
    version = "2.1.0"
    '$schema' = "https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0-rtm.5.json"
    runs = @(
        @{
            tool = @{
                driver = @{
                    name = "Veracode"
                    version = $inputJson.pipeline_scan
                    informationUri = $inputJson._links.help.href
                    rules = @(
                        $inputJson.findings | ForEach-Object {
                            @{
                                id = "$($_.issue_id)"
                                name = $_.title
                                shortDescription = @{
                                    text = $_.issue_type
                                }
                                fullDescription = @{
                                    text = $_.display_text
                                }
                                helpUri = $_.flaw_details_link
                                properties = @{
                                    tags = @("security", "injection", "OSCommandInjection")
                                    precision = "high"
                                    severity = "$($_.severity)"
                                }
                            }
                        }
                    )
                }
            }
            results = @(
                $inputJson.findings | ForEach-Object -Begin { $index = 0 } -Process {
                    @{
                        ruleId = "$($_.issue_id)"
                        ruleIndex = $index
                        level = if ($_.severity -eq 5) { "error" } else { "warning" }
                        message = @{
                            text = $_.display_text
                        }
                        locations = @(
                            @{
                                physicalLocation = @{
                                    artifactLocation = @{
                                        uri = $_.image_path
                                    }
                                    region = @{
                                        startLine = $_.files.source_file.line
                                    }
                                }
                                logicalLocation = @{
                                    name = $_.files.source_file.qualified_function_name
                                    fullyQualifiedName = $_.files.source_file.qualified_function_name
                                    kind = "function"
                                }
                            }
                        )
                        properties = @{
                            issueType = $_.issue_type_id
                            cweId = "CWE-$($_.cwe_id)"
                        }
                    }
                    $index++
                }
            )
            invocations = @(
                @{
                    executionSuccessful = $true
                    toolExecutionNotifications = @(
                        @{
                            descriptor = @{
                                id = $inputJson.scan_id
                                name = $inputJson.message
                                level = "warning"
                            }
                        }
                    )
                }
            )
        }
    )
}

# Write SARIF output to file
$sarifOutput | ConvertTo-Json -Depth 10 | Set-Content -Path "output.sarif"

Write-Host "Conversion complete. Output written to output.sarif"
