# =============================================================================
# INSTALL-GENESIS-FACTORY.ps1
# Version: 7.0 (The Safe & Modular Architecture)
# Description: This script installs Project Genesis by writing all components
#              as separate source files and then assembling them, eliminating
#              the risk of string-corruption errors.
# =============================================================================

# --- Configuration ---
# The final application will be installed in a folder named 'GenesisProject'
# in the same directory where this installer script is run.
$InstallPath = "$PSScriptRoot\GenesisProject"

# This is a temporary working directory that the installer uses to build the components.
# It will be deleted at the end.
$SourcePath = Join-Path $PSScriptRoot "_temp_genesis_src"


# --- Script Start ---
Clear-Host
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host "     Installing Project Genesis - The Safe Architecture"
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host ""
# --- Phase 1: Clean Up & Structure Creation ---
if (Test-Path $InstallPath) {
    $choice = Read-Host "The directory '$InstallPath' already exists. Do you want to overwrite it? [Y/N]"
    if ($choice -ne 'Y') {
        Write-Host "Installation aborted by user." -ForegroundColor Yellow
        return
    }
    Write-Host "Removing existing directory..." -ForegroundColor Yellow
    Remove-Item -Path $InstallPath -Recurse -Force
}
if (Test-Path $SourcePath) {
    Remove-Item -Path $SourcePath -Recurse -Force
}

Write-Host "-> Creating clean installation source structure..." -ForegroundColor Green
New-Item -Path $InstallPath -ItemType Directory | Out-Null
New-Item -Path $SourcePath -ItemType Directory | Out-Null
New-Item -Path (Join-Path $SourcePath "templates") -ItemType Directory | Out-Null
Write-Host "   Structure created successfully."
# --- Phase 2: Write Individual Source Files ---
# We write each component to our temporary source directory. This avoids
# complex, error-prone string operations.
Write-Host "-> Writing all source components to temporary location..." -ForegroundColor Green

# --- Component 2.1: The GUI Window (MainWindow.xaml) ---
@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
        Title="Project Genesis - New Project Wizard" Height="600" Width="700" 
        WindowStartupLocation="CenterScreen" Background="#2D2D30">
    <Window.Resources>
        <Style TargetType="ComboBoxItem"><Setter Property="Foreground" Value="Black"/></Style>
        <Style TargetType="RadioButton"><Setter Property="Foreground" Value="White"/></Style>
    </Window.Resources>
    <ScrollViewer VerticalScrollBarVisibility="Auto">
        <Grid Margin="20">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="Project Genesis Wizard" FontSize="24" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center" Margin="0,0,0,20"/>
            
            <StackPanel Grid.Row="1" Margin="0,0,0,10">
                <TextBlock Text="1. Enter Your Project Name:" Foreground="White" Margin="0,0,0,5" FontWeight="Bold"/>
                <TextBox x:Name="ProjectNameTextBox" Padding="5" Background="#3E3E42" Foreground="White" BorderBrush="#555" BorderThickness="1"/>
            </StackPanel>

            <StackPanel Grid.Row="2" Margin="0,10,0,10">
                <TextBlock Text="2. Select a Project Template:" Foreground="White" Margin="0,0,0,5" FontWeight="Bold"/>
                <ComboBox x:Name="TemplateComboBox" Padding="5" DisplayMemberPath="Name"/>
            </StackPanel>
            
            <StackPanel Grid.Row="3" Margin="0,10,0,10">
                <TextBlock Text="3. Define the Project Goal (for the AI):" Foreground="White" Margin="0,0,0,5" FontWeight="Bold"/>
                <TextBox x:Name="ProjectGoalTextBox" Height="80" TextWrapping="Wrap" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" Padding="5" Background="#3E3E42" Foreground="White" BorderBrush="#555" BorderThickness="1"/>
            </StackPanel>

            <StackPanel Grid.Row="4" Margin="0,10,0,10">
                <TextBlock Text="4. Choose AI Communication Style:" Foreground="White" Margin="0,0,0,5" FontWeight="Bold"/>
                <RadioButton x:Name="PersonaEasy" Content="Easy: Simple, direct instructions. For non-technical users." IsChecked="True" GroupName="Persona"/>
                <RadioButton x:Name="PersonaMedium" Content="Medium: Explanations and guidance. For learning users." GroupName="Persona"/>
                <RadioButton x:Name="PersonaExpert" Content="Expert: Technical and concise. For expert users." GroupName="Persona"/>
            </StackPanel>

            <Button x:Name="CreateProjectButton" Grid.Row="5" Content="Create Project" Padding="15,10" FontSize="16" FontWeight="Bold" Background="#007ACC" Foreground="White" BorderThickness="0" HorizontalAlignment="Center" Margin="0,20,0,0">
                <Button.Style>
                    <Style TargetType="Button">
                        <Setter Property="Cursor" Value="Hand"/>
                        <Style.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#005A9E"/>
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </Button.Style>
            </Button>
        </Grid>
    </ScrollViewer>
</Window>
'@ | Set-Content -Path (Join-Path $SourcePath "MainWindow.xaml") -Encoding UTF8
# --- Component 2.2: The GUI Logic (Start-Genesis.ps1) ---
@'
# =============================================================================
# Project Genesis: The AI-Driven Project Builder - The Factory Logic
# =============================================================================
Add-Type -AssemblyName PresentationFramework, System.Windows.Forms
$ScriptRoot = $PSScriptRoot
$TemplatesPath = Join-Path $ScriptRoot "templates"

try {
    [xml]$xaml = Get-Content -Path (Join-Path $ScriptRoot "MainWindow.xaml")
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    [System.Windows.Forms.MessageBox]::Show("Error loading GUI definition (MainWindow.xaml). Make sure the file exists in the same directory as the script.", "Fatal Error", "OK", "Error")
    return
}

# Find all GUI controls
$ProjectNameTextBox = $window.FindName("ProjectNameTextBox")
$TemplateComboBox = $window.FindName("TemplateComboBox")
$ProjectGoalTextBox = $window.FindName("ProjectGoalTextBox")
$PersonaEasy = $window.FindName("PersonaEasy")
$PersonaMedium = $window.FindName("PersonaMedium")
$PersonaExpert = $window.FindName("PersonaExpert")
$CreateProjectButton = $window.FindName("CreateProjectButton")

# Populate ComboBox by reading directory names
$templateObjects = Get-ChildItem -Path $TemplatesPath -Directory | ForEach-Object {
    [PSCustomObject]@{ Name = $_.Name; Path = $_.FullName }
}
$TemplateComboBox.ItemsSource = $templateObjects
if($templateObjects.Count -gt 0) { $TemplateComboBox.SelectedIndex = 0 }

# The main creation logic when the button is clicked
$CreateProjectButton.add_Click({
    # Gather all data from the form
    $ProjectName = $ProjectNameTextBox.Text
    $SelectedTemplate = $TemplateComboBox.SelectedItem
    $ProjectGoal = $ProjectGoalTextBox.Text
    $PersonaChoice = if ($PersonaEasy.IsChecked) { "easy" } elseif ($PersonaMedium.IsChecked) { "medium" } else { "expert" }

    # Validation
    if ([string]::IsNullOrWhiteSpace($ProjectName) -or $null -eq $SelectedTemplate -or [string]::IsNullOrWhiteSpace($ProjectGoal)) {
        [System.Windows.Forms.MessageBox]::Show("Please fill out all fields: Name, Template, and Goal.", "Validation Error", "OK", "Warning")
        return
    }
    
    $ProjectPath = Join-Path $ScriptRoot $ProjectName
    if (Test-Path $ProjectPath) {
        [System.Windows.Forms.MessageBox]::Show("A folder named '$ProjectName' already exists. Please choose another name.", "Validation Error", "OK", "Error")
        return
    }

    $CreateProjectButton.IsEnabled = $false
    $CreateProjectButton.Content = "Creating..."

    # Create the new project directory and copy template files
    New-Item -Path $ProjectPath -ItemType Directory | Out-Null
    Copy-Item -Path "$($SelectedTemplate.Path)\*" -Destination $ProjectPath -Recurse -Force
    
    # --- Generate Files from Templates ---
    # Read the content of the two main templates: the build script and the AI readme.
    $BuildScriptTemplateContent = Get-Content -Path (Join-Path $PSScriptRoot "src\build_script_template.ps1") -Raw
    $ReadmeTemplateContent = Get-Content -Path (Join-Path $PSScriptRoot "src\ai_readme_template.txt") -Raw

    # Generate the final Build.ps1 content by replacing placeholders
    $FinalBuildScriptContent = $BuildScriptTemplateContent -replace '\{\{PROJECT_NAME\}\}', $ProjectName
    Set-Content -Path (Join-Path $ProjectPath "Build.ps1") -Value $FinalBuildScriptContent -Encoding UTF8

    # Generate the final AI_README.txt content by replacing placeholders
    $FinalReadmeContent = $ReadmeTemplateContent -replace '\{\{PROJECT_NAME\}\}', $ProjectName -replace '\{\{PROJECT_GOAL\}\}', $ProjectGoal -replace '\{\{PERSONA_CHOICE\}\}', $PersonaChoice -replace '\{\{TEMPLATE_NAME\}\}', $SelectedTemplate.Name -replace '\{\{BUILD_SCRIPT_CODE\}\}', $FinalBuildScriptContent
    
    # Append the source code of all other project files to the AI README
    $projectFiles = Get-ChildItem -Path $ProjectPath -Recurse -Exclude "AI_README.txt", "Build.ps1"
    foreach ($file in $projectFiles) {
        $FinalReadmeContent += "`n--- FILE: $($file.Name) ---\n"
        $FinalReadmeContent += "````n"
        $FinalReadmeContent += (Get-Content -Path $file.FullName -Raw)
        $FinalReadmeContent += "`n````"
    }
    Set-Content -Path (Join-Path $ProjectPath "AI_README.txt") -Value $FinalReadmeContent -Encoding UTF8

    [System.Windows.Forms.MessageBox]::Show("Project '$ProjectName' created successfully! The single AI_README.txt file contains all necessary context.", "Success", "OK", "Information")
    $window.Close()
})

$window.ShowDialog() | Out-Null
'@ | Set-Content -Path (Join-Path $SourcePath "Start-Genesis.ps1") -Encoding UTF8
# --- Component 2.3: The Template for the AI Onboarding Document (AI_README.txt) ---
@'
# AI Project Context: {{PROJECT_NAME}}

################################################################################
# AI ONBOARDING DOCUMENT: PROJECT '{{PROJECT_NAME}}'
################################################################################

This is the single source of truth for our project. As my AI assistant, you must read and understand this entire document to collaborate effectively.

---
## SECTION 1: CORE PROJECT DIRECTIVES
---

### 1.1: Project Goal
{{PROJECT_GOAL}}

### 1.2: Your Persona
**MANDATORY INSTRUCTION:** For all interactions within this project, you must adopt the **'{{PERSONA_CHOICE}}'** persona. The descriptions are:
- **easy:** The user has minimal technical knowledge. Provide simple, direct, step-by-step instructions. Avoid all complex language and jargon.
- **medium:** The user has some programming knowledge and wants to learn more. Explain the 'why' behind technical decisions. Act as a mentor.
- **expert:** The user is in full control. Expect technical precision and efficiency. Provide concise, data-driven answers and focus on optimal strategies.

---
## SECTION 2: PROJECT AUTOMATION TOOL: Build.ps1
---

This project contains its own PowerShell automation script, `Build.ps1`. This is your primary tool for managing project versions.

### How to Use Build.ps1
When I, the user, ask you to 'create a new version' or 'make a build', you must instruct me to execute the following command in a PowerShell terminal in this project's root directory:
`.\Build.ps1`

### Build.ps1 - Full Source Code
This is the code for the `Build.ps1` script so you can understand its functionality:
```powershell
{{BUILD_SCRIPT_CODE}}
 ```

 ---
 ## SECTION 3: INITIAL PROJECT SOURCE CODE
 ---

# Here is the full content of every file included in the project template:
'@ | Set-Content -Path (Join-Path $SourcePath "ai_readme_template.txt") -Encoding UTF8
# --- Component 2.4: The Template for the Project-Specific Build Script (Build.ps1) ---
@'
# --- Project Build Script for {{PROJECT_NAME}} ---
# This script manages the build, versioning, and backup process for THIS project.
[CmdletBinding()]
param ([Switch]$Release)

# Configuration
$ProjectName = $PSScriptRoot.Split('\')[-1]
$BackupDirPath = Join-Path $PSScriptRoot "_backups"
$ManifestPath = Join-Path $PSScriptRoot "manifest.json" # Example for extensions
$NewVersion = "1.0.0"

# Versioning Logic
# Tries to read the version from a manifest.json, if it exists.
if (Test-Path $ManifestPath) {
    try {
        $OldVersion = (Get-Content $ManifestPath | ConvertFrom-Json).version
        $VersionParts = $OldVersion.Split('.')
        $VersionParts[-1] = ([int]$VersionParts[-1] + 1).ToString()
        $NewVersion = $VersionParts -join '.'
    } catch {
        # If manifest is broken or version is missing, start from 1.0.0
        $OldVersion = "1.0.0"
    }
} else {
    $OldVersion = "1.0.0"
}

# ZIP Backup
# Always creates a versioned ZIP file of the current state before making changes.
if (-not (Test-Path $BackupDirPath)) { New-Item -Path $BackupDirPath -ItemType Directory | Out-Null }
$ZipFileName = "${ProjectName}_v${OldVersion}.zip"
$ZipFullPath = Join-Path $BackupDirPath $ZipFileName
$itemsToArchive = Get-ChildItem -Path $PSScriptRoot -Exclude "_backups"
Compress-Archive -Path $itemsToArchive.FullName -DestinationPath $ZipFullPath -Force
Write-Host "Backup of v$($OldVersion) created at `_backups\$($ZipFileName)" -ForegroundColor Green

# Update Manifest
# If a manifest exists, this will update its version number.
if (Test-Path $ManifestPath) {
    $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
    $manifest.version = $NewVersion
    $manifest | ConvertTo-Json -Depth 5 | Set-Content $ManifestPath -Encoding UTF8
    Write-Host "manifest.json updated to v$($NewVersion)." -ForegroundColor Cyan
}

# Future Git Release Logic
if ($Release) {
    Write-Host "Release functionality is not yet implemented. This would be the place to add 'git' and 'gh' commands." -ForegroundColor Yellow
}

Write-Host "Build process complete for v$($NewVersion)." -ForegroundColor Green
'@ | Set-Content -Path (Join-Path $SourcePath "build_script_template.ps1") -Encoding UTF8

Write-Host "   Source files for templates and GUI written successfully."
# --- Phase 3: Create Raw Source Code Templates ---
# These are the "dumb" templates that the Genesis wizard will copy.
Write-Host "-> Building raw code templates..." -ForegroundColor Green

# Template 3.1: Python-API
$templatePath = Join-Path $SourcePath "templates\Python-API"
New-Item -Path $templatePath -ItemType Directory -Force | Out-Null
Set-Content -Path "$templatePath\main.py" -Value "from fastapi import FastAPI`napp = FastAPI()`n`n@app.get('/')`ndef root():`n    return {'message': 'AI API running'}"
Set-Content -Path "$templatePath\requirements.txt" -Value "fastapi`nuvicorn"
Set-Content -Path "$templatePath\.gitignore" -Value "__pycache__/`n.env`nvenv/"

# Template 3.2: Chrome-Extension
$templatePath = Join-Path $SourcePath "templates\Chrome-Extension"
New-Item -Path $templatePath -ItemType Directory -Force | Out-Null
Set-Content -Path "$templatePath\manifest.json" -Value '{ "name": "My New AI Extension", "version": "1.0.0", "manifest_version": 3 }'
Set-Content -Path "$templatePath\popup.html" -Value '<html><body><h1>My AI Extension</h1></body></html>'

Write-Host "   Templates created."

# --- Phase 4: Final Assembly ---
# Move the fully built components from the temporary 'src' directory
# to the final 'GenesisProject' directory.
Write-Host "-> Assembling the final Genesis application..." -ForegroundColor Green
Move-Item -Path (Join-Path $SourcePath "templates") -Destination $InstallPath -Force
Move-Item -Path (Join-Path $SourcePath "MainWindow.xaml") -Destination $InstallPath -Force
Move-Item -Path (Join-Path $SourcePath "ai_readme_template.txt") -Destination (Join-Path $InstallPath "src") -Force # Move templates to final src
Move-Item -Path (Join-Path $SourcePath "build_script_template.ps1") -Destination (Join-Path $InstallPath "src") -Force
# The main starter script is generated inside the final install path
Get-Content -Path (Join-Path $SourcePath "Start-Genesis.ps1") | Set-Content -Path (Join-Path $InstallPath "Start-Genesis.ps1") -Encoding UTF8

# --- Final Cleanup ---
# Remove the temporary source directory, as it's no longer needed.
Remove-Item -Path $SourcePath -Recurse -Force
Write-Host "   Assembly complete and temporary files removed."

# --- Final Instructions ---
Write-Host ""
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host "     INSTALLATION COMPLETE"
Write-Host "====================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "The 'GenesisProject' is now ready in the same folder as this installer." -ForegroundColor Green
Write-Host "To start, run the 'Start-Genesis.ps1' file inside the 'GenesisProject' folder." -ForegroundColor Yellow
Write-Host ""
