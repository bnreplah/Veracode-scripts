# # PHP IDE packager helper script
## The purpose of this script is to quickly package the code and place it inside the .verascan folder with the new Veracode IDE plugins 
##  to work with PHPSTORM

# # Define the directory to be archived
# $sourceDirectory = "C:\Users\BenHalpern\git\OWASPWebGoatPHP"
# Work in progress
# # Define the output zip file path
# $zipFilePath = "C:\Users\BenHalpern\git\OWASPWebGoatPHP\.verascan\archive.zip"

# # Define the file extensions to include
# $fileExtensions = @("*.php", "*.module", "*.inc", "*.html", "*.htm", "*.profile", "*.install", "*.engine", "*.theme", "*.php4", "*.php5", "*.php7", "*.phtml")

# # Get all files with the specified extensions in the directory and subdirectories
# $filesToArchive = Get-ChildItem -Path $sourceDirectory -Recurse -Include $fileExtensions

# # Compress the files into a zip archive
# Compress-Archive -Path $filesToArchive.FullName -DestinationPath $zipFilePath



# Fetch the current project directory from an environment variable or a file
# For simplicity, assume you set this environment variable manually or through another script
$projectDirectory = $env:PHPSTORM_PROJECT_PATH

# If not using an environment variable, you can manually set it as follows:
# $projectDirectory = "C:\path\to\phpstorm\project"

# Define the .verascan directory path
$verascanDirectory = Join-Path -Path $projectDirectory -ChildPath ".verascan"

# Check if the .verascan directory exists, if not, create it
if (-not (Test-Path -Path $verascanDirectory)) {
    New-Item -Path $verascanDirectory -ItemType Directory
}

# Define the output zip file path inside the .verascan directory
$zipFileName = "archive.zip"
$zipFilePath = Join-Path -Path $verascanDirectory -ChildPath $zipFileName

# Define the file extensions to include
$fileExtensions = @("*.php", "*.module", "*.inc", "*.html", "*.htm", "*.profile", "*.install", "*.engine", "*.theme", "*.php4", "*.php5", "*.php7", "*.phtml")

# Get all files with the specified extensions in the directory and subdirectories
$filesToArchive = Get-ChildItem -Path $projectDirectory -Recurse -Include $fileExtensions

# Compress the files into a zip archive
Compress-Archive -Path $filesToArchive.FullName -DestinationPath $zipFilePath
