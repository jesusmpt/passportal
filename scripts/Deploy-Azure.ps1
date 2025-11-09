# Deploy-Azure.ps1
# Script para desplegar automáticamente en Azure

param(
    [string]$ResourceGroupName = "assets",
    [string]$Location = "spain",
    [string]$AppName = "passwordless-portal-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
)

Write-Host "🚀 INICIANDO DESPLIEGUE EN AZURE" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Verificar que estamos logueados en Azure
try {
    $context = Get-AzContext
    if (-not $context) {
        throw "No hay sesión activa en Azure. Ejecuta 'Connect-AzAccount' primero."
    }
    Write-Host "✅ Conectado a Azure: $($context.Account.Id)" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}

# Crear Resource Group
Write-Host "`n📦 Creando Resource Group..." -ForegroundColor Yellow
try {
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
    Write-Host "✅ Resource Group creado: $ResourceGroupName" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Resource Group ya existe o error: $_" -ForegroundColor Yellow
}

# Crear App Service Plan
Write-Host "`n📊 Creando App Service Plan..." -ForegroundColor Yellow
try {
    $appServicePlan = New-AzAppServicePlan `
        -ResourceGroupName $ResourceGroupName `
        -Name "$AppName-plan" `
        -Location $Location `
        -Tier "Standard" `
        -WorkerSize "Small" `
        -NumberofWorkers 1
    Write-Host "✅ App Service Plan creado" -ForegroundColor Green
} catch {
    Write-Host "❌ Error creando App Service Plan: $_" -ForegroundColor Red
    exit 1
}

# Crear Web App
Write-Host "`n🌐 Creando Web App..." -ForegroundColor Yellow
try {
    $webApp = New-AzWebApp `
        -ResourceGroupName $ResourceGroupName `
        -Name $AppName `
        -Location $Location `
        -AppServicePlan "$AppName-plan"
    Write-Host "✅ Web App creada: $AppName" -ForegroundColor Green
} catch {
    Write-Host "❌ Error creando Web App: $_" -ForegroundColor Red
    exit 1
}

# Configurar settings
Write-Host "`n⚙️ Configurando aplicación..." -ForegroundColor Yellow
try {
    $appSettings = @{
        "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
        "NODE_ENV" = "production"
        "PORT" = "8080"
    }
    
    Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName -AppSettings $appSettings
    Write-Host "✅ Configuración aplicada" -ForegroundColor Green
} catch {
    Write-Host "❌ Error configurando aplicación: $_" -ForegroundColor Red
    exit 1
}

# Mostrar información final
Write-Host "`n🎉 DESPLIEGUE COMPLETADO" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green
Write-Host "`n📋 INFORMACIÓN DE LA APLICACIÓN:" -ForegroundColor Yellow
Write-Host "URL: https://$AppName.azurewebsites.net" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "Región: $Location" -ForegroundColor White

Write-Host "`n🔗 Próximos pasos:" -ForegroundColor Cyan
Write-Host "1. Configurar Azure AD App Registration" -ForegroundColor White
Write-Host "2. Actualizar clientId en auth.js" -ForegroundColor White
Write-Host "3. Configurar redirect URIs en Azure AD" -ForegroundColor White
Write-Host "`n💡 Ejecuta .\scripts\Configure-AD.ps1 para configurar Azure AD" -ForegroundColor Yellow