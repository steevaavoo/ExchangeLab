# Self-explanatory. .\vagrant folder can be unreliable - safer to copy to C:\ and run scripts from there
Write-Host 'Copying Exchange Installation files to C:\Source - this will take about 5 minutes - 5.6GB!'
Copy-Item "C:\Vagrant\Source" -Destination "C:\" -Recurse -Force
Write-Host 'Done!'
