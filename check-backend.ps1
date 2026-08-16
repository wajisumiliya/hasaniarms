try {
  $r = Invoke-RestMethod http://localhost:5000/health
  $r | Format-List
} catch {
  Write-Host "Backend is not reachable on port 5000." -ForegroundColor Red
  Write-Host $_
}
