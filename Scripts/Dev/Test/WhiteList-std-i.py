
class scanUrl:
    def __init__(self):
        pass

    def __str__(self):
        pass

    def create(self):
        pass

class AuthenticationConfiguration:
    def __init__(self):
        pass

    def __str__(self):
        pass

    def create(self):
        pass


class CrawlConfiguration:
    def __init__(self):
        pass

    def __str__(self):
        pass

    def create(self):
        pass

class ScanSetting:
    def __init__(self):
        pass
   
    def __str__(self):
        pass

    def create(self):
        pass

class ScannerVariable:
    def __init__(self):
        pass

    def __str__(self):
        pass

    def create(self):
        pass

class ApiScanSettingRequest:
    def __init__(self):
        pass

    def __str__(self):
        pass

    def create(self):
        pass

# def menu():
#     print("==================== VERACODE DAST BULK WHITE LIST ====================")
#     print("\t\t1)")
#     print("\t\t2)")
#     print("\t\t3)")
#     print("\t\t4)")
#     print("\t\t5)")
#     print("\t\t6)")
#     print("\t\t7)")
#     print("\t\t8)")
#     print("\t\t9)")


# ScanConfiguration:
#     description: >
#       The configuration for a URL scan.
#     type: object
#     properties:
#       target_url:
#         description: Target URL for the scan with rules, such as a scan of both HTTP and HTTPS protocols or the restriction of the URL scan to a specific directory type.
#         $ref: '#/definitions/ScanURL'
#       allowed_hosts:
#         type: array
#         description: Additional allowed hosts for the URL scan with rules, such as a scan of both HTTP and HTTPS protocols or the restriction of the URL scan to a specific directory type.
#         items:
#           $ref: '#/definitions/ScanURL'
#       api_scan_setting:
#         $ref: '#/definitions/ApiScanSetting'
#       auth_configuration:
#         description: Authentication configuration for the URL scan.
#         $ref: '#/definitions/AuthenticationConfiguration'
#       crawl_configuration:
#         description: Crawl configuration for the URL scan.
#         $ref: '#/definitions/CrawlConfiguration'
#       scan_setting:
#         description: >
#           Settings for the URL scan. You do not have to specify all the settings. Any settings you do specify at the
#           URL scan configuration level override or add to the Dynamic Analysis configuration level.
#         $ref: '#/definitions/ScanSetting'
#       scanner_variables:
#         description: >
#           The list of scan engine variables specified for the URL scan. Any scan engine variables specified at the URL scan configuration
#           level override or add to the list of scan engine variables specified at the Dynamic Analysis configuration and Organization level.
#         type: array
#         items:
#           $ref: '#/definitions/ScannerVariable'
#       scanner_variable_reference_keys:
#         description: >
#           The list of reference keys of scan engine variables specified for the URL scan. Any scan engine variables specified at the URL scan configuration
#           level override or add to the list of scan engine variables specified at the Dynamic Analysis configuration and Organization level.
#         type: array
#         items:
#           type: string
#       capabilities:
#         type: array
#         items:
#           type: string



class ScanConfiguration:
    def __init__(self):
        pass

    def __str__(self):
        pass

    def create(self):
        pass

class OrgInformation:
    def __init__(self):
        pass

    def __str__(self):
        pass

    def create(self):
        pass

# ScanConfigurationRequest:
#     description: >
#       The scan configuration request for a URL or API specification scan.
#     type: object
#     properties:
#       allowed_hosts:
#         type: array
#         description: Additional allowed hosts for the URL scan with rules, such as a scan of both HTTP and HTTPS protocols or the restriction of the URL scan to a specific directory type.
#         items:
#           $ref: '#/definitions/ScanURL'
#       auth_configuration:
#         description: Authentication configuration for the URL scan.
#         $ref: '#/definitions/AuthenticationConfiguration'
#       api_scan_setting:
#         description: API scan settings. Required for analyses that are of type API_SCAN.
#         $ref: '#/definitions/ApiScanSettingRequest'
#       crawl_configuration:
#         description: Crawl configuration for the URL scan.
#         $ref: '#/definitions/CrawlConfiguration'
#       scan_setting:
#         description: URL scan setting. Not mandatory and not everything must be specified.
#         $ref: '#/definitions/ScanSetting'
#       target_url:
#         description: Target URL for the scan with rules such as a scan of both HTTP and HTTPS protocols or the restriction of the URL scan to a specific directory type.
#         $ref: '#/definitions/ScanURL'
#       scanner_variables:
#         type: array
#         description: The optional list of user-defined, URL scan-level scan engine variables.
#         items:
#           $ref: '#/definitions/ScannerVariableRequest'


class ScanConfigurationRequest:
    def __init__(self):
        pass

    def __str__(self):
        pass

    def create(self):
        pass

class ScanSchedule:
    def __init__(self):
        pass

    def __str__(self):
        pass

    def create(self):
        pass

