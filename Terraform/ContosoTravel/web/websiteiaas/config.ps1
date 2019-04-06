iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install IIS
Install-WindowsFeature Web-Server,Web-Asp-Net45,NET-Framework-Features

choco install dotnetcore-windowshosting --version 2.2.3

# Restart the web server so that system PATH updates take effect
net stop was /y
net start w3svc

