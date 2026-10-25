# Push to GitHub — run this in PowerShell or Windows Terminal
# Git Credential Manager will open a browser window for GitHub authentication

$gitExe = "C:\Program Files\Git\cmd\git.exe"
$repoDir = "C:\Users\harsha.tatti\Flutter-Project\Flutter-Project"

Write-Host "=== Pushing to GitHub ===" -ForegroundColor Cyan
Write-Host "Remote: origin (https://github.com/HarshaTatti/Flutter-Project.git)" -ForegroundColor Gray
Write-Host ""
Write-Host "A browser window may open for GitHub authentication." -ForegroundColor Yellow
Write-Host ""

Set-Location $repoDir
& $gitExe push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== SUCCESS: Pushed to GitHub! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps for Render deployment:" -ForegroundColor Cyan
    Write-Host "1. Go to https://dashboard.render.com" -ForegroundColor White
    Write-Host "2. Click 'New +' > 'Blueprint'" -ForegroundColor White
    Write-Host "3. Connect your GitHub repository: HarshaTatti/Flutter-Project" -ForegroundColor White
    Write-Host "4. Render will auto-detect render.yaml and configure everything" -ForegroundColor White
    Write-Host "5. Click 'Apply' and your app will deploy to https://<your-app>.onrender.com" -ForegroundColor White
} else {
    Write-Host "Push failed. Please check your GitHub credentials." -ForegroundColor Red
}
