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
