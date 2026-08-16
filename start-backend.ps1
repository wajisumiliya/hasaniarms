Set-Location "$PSScriptRoot\backend"
if (-not (Test-Path ".env")) { Copy-Item ".env.example" ".env" }
npm install
npm start
