
# =============================================================================
# GENESIS-WIZARD.ps1
# Version: 8.0 (The Final, Self-Contained Architecture)
# Description: A single, standalone script that provides a GUI to generate
#              complete, AI-ready projects without any external dependencies
#              or complex installation steps.
# =============================================================================

# --- Phase 1: GUI Setup ---
Add-Type -AssemblyName PresentationFramework, System.Windows.Forms

# Define the GUI in XAML as a Here-String
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Project Genesis - New Project Wizard" Height="600" Width="700" WindowStartupLocation="CenterScreen" Background="#2D2D30"><Window.Resources><Style TargetType="ComboBoxItem"><Setter Property="Foreground" Value="Black"/></Style><Style TargetType="RadioButton"><Setter Property="Foreground" Value="White"/></Style></Window.Resources><ScrollViewer VerticalScrollBarVisibility="Auto"><Grid Margin="20"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions><TextBlock Grid.Row="0" Text="Project Genesis Wizard" FontSize="24" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center" Margin="0,0,0,20"/><StackPanel Grid.Row="1" Margin="0,0,0,10"><TextBlock Text="1. Enter Your Project Name:" Foreground="White" Margin="0,0,0,5" FontWeight="Bold"/><TextBox x:Name="ProjectNameTextBox" Padding="5" Background="#3E3E42" Foreground="White" BorderBrush="#555" BorderThickness="1"/></StackPanel><StackPanel Grid.Row="2" Margin="0,10,0,10"><TextBlock Text="2. Select a Project Template:" Foreground="White" Margin="0,0,0,5" FontWeight="Bold"/><ComboBox x:Name="TemplateComboBox" Padding="5" DisplayMemberPath="Name"/></StackPanel><StackPanel Grid.Row="3" Margin="0,10,0,10"><TextBlock Text="3. Define the Project Goal (for the AI):" Foreground="White" Margin="0,0,0,5" FontWeight="Bold"/><TextBox x:Name="ProjectGoalTextBox" Height="80" TextWrapping="Wrap" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" Padding="5" Background="#3E3E42" Foreground="White" BorderBrush="#555" BorderThickness="1"/></StackPanel><StackPanel Grid.Row="4" Margin="0,10,0,10"><TextBlock Text="4. Choose AI Communication Style:" Foreground="White" Margin="0,0,0,5" FontWeight="Bold"/><RadioButton x:Name="PersonaEasy" Content="Easy: Simple, direct instructions. For non-technical users." IsChecked="True" GroupName="Persona"/><RadioButton x:Name="PersonaMedium" Content="Medium: Explanations and guidance. For learning users." GroupName="Persona"/><RadioButton x:Name="PersonaExpert" Content="Expert: Technical and concise. For expert users." GroupName="Persona"/></StackPanel><Button x:Name="CreateProjectButton" Grid.Row="5" Content="Create Project" Padding="15,10" FontSize="16" FontWeight="Bold" Background="#007ACC" Foreground="White" BorderThickness="0" HorizontalAlignment="Center" Margin="0,20,0,0"><Button.Style><Style TargetType="Button"><Setter Property="Cursor" Value="Hand"/><Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#005A9E"/></Trigger></Style.Triggers></Style></Button.Style></Button></Grid></ScrollViewer></Window>
"@
$reader = New-Object System.Xml.XmlNodeReader([xml]$xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    [System.Windows.Forms.MessageBox]::Show("Failed to load GUI. Please ensure you are running a modern version of Windows with .NET Framework.", "Fatal Error", "OK", "Error")
    return
}

# --- Phase 2: Define Templates and GUI Logic ---
# Find all GUI controls
$ProjectNameTextBox = $window.FindName("ProjectNameTextBox")
$TemplateComboBox = $window.FindName("TemplateComboBox")
$ProjectGoalTextBox = $window.FindName("ProjectGoalTextBox")
$PersonaEasy = $window.FindName("PersonaEasy")
$PersonaMedium = $window.FindName("PersonaMedium")
$PersonaExpert = $window.FindName("PersonaExpert")
$CreateProjectButton = $window.FindName("CreateProjectButton")

# Define templates directly inside the script
$templates = @{
    "Python-API" = @{
        Description = "A simple FastAPI backend for AI tasks."
        Files = @{
            "main.py" = "from fastapi import FastAPI`napp = FastAPI()`n`n@app.get('/')`ndef root():`n    return {'message': 'AI API running'}"
            "requirements.txt" = "fastapi`nuvicorn"
            ".gitignore" = "__pycache__/`n.env`nvenv/"
        }
    }
    "Chrome-Extension" = @{
        Description = "A basic boilerplate for a browser extension."
        Files = @{
            "manifest.json" = '{ "name": "{{PROJECT_NAME}}", "version": "1.0.0", "manifest_version": 3 }'
        }
    }
}

# Populate ComboBox
$TemplateComboBox.ItemsSource = $templates.Keys
$TemplateComboBox.SelectedIndex = 0

# --- Phase 3: Main Creation Logic ---
$CreateProjectButton.add_Click({
    # Gather all data from the form
    $ProjectName = $ProjectNameTextBox.Text
    $SelectedTemplateName = $TemplateComboBox.SelectedItem
    $ProjectGoal = $ProjectGoalTextBox.Text
    $PersonaChoice = if ($PersonaEasy.IsChecked) { "easy" } elseif ($PersonaMedium.IsChecked) { "medium" } else { "expert" }

    # Validation
    if ([string]::IsNullOrWhiteSpace($ProjectName) -or [string]::IsNullOrWhiteSpace($ProjectGoal)) {
        [System.Windows.Forms.MessageBox]::Show("Please provide a project name and a goal.", "Validation Error", "OK", "Warning"); return
    }
    
    $ProjectPath = Join-Path $PSScriptRoot $ProjectName
    if (Test-Path $ProjectPath) {
        [System.Windows.Forms.MessageBox]::Show("A folder named '$ProjectName' already exists.", "Validation Error", "OK", "Error"); return
    }
    $CreateProjectButton.IsEnabled = $false; $CreateProjectButton.Content = "Creating..."
    
    # --- Create Project ---
    New-Item -Path $ProjectPath -ItemType Directory | Out-Null
    
    # Copy template files
    $templateData = $templates[$SelectedTemplateName]
    foreach ($fileEntry in $templateData.Files.GetEnumerator()) {
        $fileContent = $fileEntry.Value -replace '\{\{PROJECT_NAME\}\}', $ProjectName
        Set-Content -Path (Join-Path $ProjectPath $fileEntry.Name) -Value $fileContent -Encoding UTF8
    }

    # --- Generate the Intelligent Build Script ---
    $BuildScriptContent = "# --- Project Build Script for $($ProjectName) ---`n[CmdletBinding()]`nparam ([Switch]`$Release)`n`$ProjectName = `$PSScriptRoot.Split('\')[-1]`n`$BackupDirPath = Join-Path `$PSScriptRoot `"_backups`"`nWrite-Host `"Build script for $($ProjectName) executed.`""
    Set-Content -Path (Join-Path $ProjectPath "Build.ps1") -Value $BuildScriptContent -Encoding UTF8
    
    # --- Generate the Single Source of Truth AI README ---
    $readmeContent = @"
################################################################################
# AI ONBOARDING DOCUMENT: PROJECT '$($ProjectName)'
################################################################################

This is the single source of truth for our project.

---
## SECTION 1: CORE PROJECT DIRECTIVES
---
### 1.1: Project Goal
$($ProjectGoal)

### 1.2: Your Persona
**MANDATORY INSTRUCTION:** For all interactions, you must adopt the **'$($PersonaChoice)'** persona.
- **easy:** Simple, step-by-step instructions. No jargon.
- **medium:** Explain the ''why''. Be a mentor.
- **expert:** Technical, concise, and efficient.

---
## SECTION 2: PROJECT AUTOMATION TOOL: Build.ps1
---
When I ask to 'create a new version', instruct me to run .\Build.ps1 in the project''s terminal.
Here is its source code for your reference:
```powershell
$($BuildScriptContent)
```
---
## SECTION 3: INITIAL PROJECT SOURCE CODE
---
"@
    $projectFiles = Get-ChildItem -Path $ProjectPath -Recurse -Exclude "AI_README.txt", "Build.ps1"
    foreach ($file in $projectFiles) { $readmeContent += "`n--- FILE: $($file.Name) ---\n````````n$((Get-Content -Path $file.FullName -Raw).TrimEnd())`n````````" }
    Set-Content -Path (Join-Path $ProjectPath "AI_README.txt") -Value $readmeContent -Encoding UTF8

    [System.Windows.Forms.MessageBox]::Show("Project '$ProjectName' created successfully!", "Success", "OK", "Information")
    $window.Close()
})

# --- Phase 4: Show the GUI ---
$window.ShowDialog() | Out-Null
