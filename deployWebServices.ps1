# ------------------------------
$versionNo    = '0.97'
$versionDate  = '12.12.2022'
$computerName = $env:computername
# ------------------------------
function DeployService()
{
  param
  (
    [string[]]$paraServerList,
    [string  ]$paraWebService,
    [string  ]$paraSubName   ,
    [string  ]$paraAppPool   ,
    [string  ]$paraVersion   ,
    [string  ]$paraAction
  )

  $paraAction = $paraAction.ToUpper()
  if ($paraAction -eq '0')
  {
    return ""
  }

  Clear-Host
  Write-Host ""
  Write-Host "---------------------------------------------------------------"

  foreach ($destServer in $paraServerList)
  {
    $username        = 'ranger\guidok'
    $password        = 'vy441-gk'
    $securePassword  = ConvertTo-SecureString $password -AsPlainText -Force
    $credential      = New-Object System.Management.Automation.PSCredential $username, $securePassword

    $datum           = Get-Date

    $destServerMkt   = $destServer + ".ranger.mkt"
    $destPathSrv     = "\\$destServer\c$\inetpub\wwwroot\$paraWebService$paraVersion\"
    $destPathBin     = $destPathSrv + "bin\"
    $destPathOld     = $destPathSrv + ".history\" + $datum.ToString("yyyy-MM-dd-HH-mm") + "\"

    $sourcePathSrv   = "..\\$paraWebService$paraSubName\"
    $fileNameDll     = $paraWebService + ".dll"
    $fileNameCpt     = "OmsoCryptNet.Ciphers.dll"
    $fileNameCfg     = "web.config"
    $fileNameLng     = "ServiceAPP.translation.xml"

    if ($paraWebService.ToLower() -eq 'webserviceivrapp')
    {
      $sourcePathSrv = "..\\webserviceivr\"
      $fileNameDll   = "webserviceivr.dll"
    }
    if ($paraWebService.ToLower() -eq 'webservicedtk'   )
    {
      $sourcePathSrv = "..\\webservicedtk\webservicedtk\"
      $fileNameDll   = "webservicedtk.dll"
    }
    if ($paraWebService.ToLower() -eq 'webservicedtkapp')
    {
      $sourcePathSrv = "..\\webservicedtk\webservicedtk\"
      $fileNameDll   = "webservicedtk.dll"
    }

    $sourcePathBin   = $sourcePathSrv + "bin\"
    $show            = $destServer + " - " + $paraWebService + $paraVersion + ":"

    if ($paraAction -eq '9')
    {
      Write-Host "$show Alten WebService archivieren..."
      New-item $destPathOld -itemtype directory | Out-Null
      if (Test-Path $destPathBin$fileNameDll  ) { Copy-Item -Path $destPathBin$fileNameDll   -Destination $destPathOld }
      if (Test-Path $destPathSrv$fileNameCfg  ) { Copy-Item -Path $destPathSrv$fileNameCfg   -Destination $destPathOld }
      if (Test-Path $destPathSrv$fileNameLng  ) { Copy-Item -Path $destPathSrv$fileNameLng   -Destination $destPathOld }

      Write-Host "$show Neuen Service installieren..."
      if (Test-Path $sourcePathBin$fileNameDll) { Copy-Item -Path $sourcePathBin$fileNameDll -Destination $destPathBin }
      if (Test-Path $sourcePathBin$fileNameCpt) { Copy-Item -Path $sourcePathBin$fileNameCpt -Destination $destPathBin }
      if (Test-Path $sourcePathSrv$fileNameLng) { Copy-Item -Path $sourcePathSrv$fileNameLng -Destination $destPathSrv }
    }

    Write-Host "$show Restart APPPool '$paraAppPool$paraVersion'"
    $destSession = New-PSSession -ComputerName $destServerMkt -Credential $credential
    $destAppPool = $paraAppPool + $paraVersion
    Invoke-Command   -Session $destSession  -ScriptBlock {Restart-WebAppPool -Name $Using:destAppPool}
    Remove-PSSession -Session $destSession
  }

  Write-Host ""
  Write-Host ""
  pause
}
# ------------------------------
function ShowMenuAppPool()
{
  Clear-Host
  Write-Host "---------------------------------------------------------------"
  Write-Host "Welcher Service/AppPool soll es denn sein? (V. $versionNo / $versionDate / $computerName)"
  Write-Host "---------------------------------------------------------------"

  Write-Host ""
  Write-Host "'1' - AppPoolIVR"
  Write-Host "'2' - AppPoolIVRApp"
  Write-Host ""
  Write-Host "'3' - AppPoolDTK"
  Write-Host "'4' - AppPoolDTKApp"
  Write-Host ""
  Write-Host "'6' - AppPoolB2B VCS24"
  Write-Host ""
  Write-Host "'7' - AppPoolWLE"
  Write-Host "'8' - AppPoolApp"

  Write-Host ""
  Write-Host "oder"
  Write-Host ""
  Write-Host "'0' - Abbruch"
  Write-Host "---------------------------------------------------------------"
  Write-Host ""

  return Read-Host "Bitte die Nummer und die Eingabetaste"
}

# ------------------------------
function ShowMenuVersion()
{
   param
   (
     [string]$paramServer
   )

  Clear-Host
  Write-Host ""
  Write-Host "---------------------------------------------------------------"
  Write-Host "Test- oder Produktivsystem von '$paramServer' anpassen?"
  Write-Host "---------------------------------------------------------------"

  Write-Host ""
  Write-Host "'1' - Testsystem"
  Write-Host "'9' - Produktivsystem"
  Write-Host ""
  Write-Host "oder"
  Write-Host ""
  Write-Host "'0' - Abbruch"
  Write-Host ""
  Write-Host "---------------------------------------------------------------"
  Write-Host ""

  return Read-Host "Bitte die Nummer und die Eingabetaste"
}

# ------------------------------
function ShowMenuDeploy()
{
  param
  (
    [string]$paramServer
  )

  $deployShow = "0"
  $psName     = [Environment]::GetCommandLineArgs()[0] + $MyInvocation.ScriptName
  if ($psName.IndexOf("deployWebServices") -gt -1)
  {
    $deployShow = "1"
  }

  Clear-Host
  Write-Host ""
  Write-Host "---------------------------------------------------------------"
  Write-Host "Installation & Restart oder nur Restart von '$paramServer'?"
  Write-Host "---------------------------------------------------------------"
  Write-Host ""
  Write-Host "'1' - Restart"

  if ($deployShow -eq "1")
  {
    Write-Host "'9' - Deploy & Restart"
  }

  Write-Host ""
  Write-Host "oder"
  Write-Host ""
  Write-Host "'0' - Abbruch"
  Write-Host ""
  Write-Host "---------------------------------------------------------------"
  Write-Host ""

  return Read-Host "Bitte die Nummer und die Eingabetaste"
}

do
{
  $backColor   = "Blue"
  $foreColor   = "White"

  $PSName      = ""
  $ServerList  = ""
  $WebService  = ""
  $SubName     = ""
  $AppPool     = ""
  $Version     = ""

  $Host.UI.RawUI.BackgroundColor = $backColor
  $Host.UI.RawUI.ForegroundColor = $foreColor

  if ($PSName -eq "") { $PSName = $MyInvocation.MyCommand.Name           }
  if ($PSName -eq "") { $PSName = [Environment]::GetCommandLineArgs()[0] }

  $menuAppPool = ShowMenuAppPool
  switch ($menuAppPool.ToUpper())
  {
    '0' {return}

    '1' {
          $WebService  = "WebServiceIVR"
          $AppPool     = "AppPoolIVR"
          $menuVersion = ShowMenuVersion $AppPool
          switch ($menuVersion.ToUpper())
          {
            '1' {
                  $ServerList = "dehoiisDTK1"
                  $Version    = "Test"
                }
            '9' {
                  $ServerList = "dehoiisDTK1",
                                "dehoiisDTK2",
                                "dehoiisDTK3",
                                "dehoiisDTK4",
                                "dehoiisDTK5"
                }
          }

          if ($ServerList -ne '')
          {
            $menuDeploy = ShowMenuDeploy $AppPool
            DeployService  $ServerList $WebService $SubName $AppPool $Version $menuDeploy
          }
        }

    '2' {
          $WebService  = "WebServiceIVRApp"
          $AppPool     = "AppPoolIVRApp"
          $menuVersion = ShowMenuVersion $AppPool
          switch ($menuVersion.ToUpper())
          {
            '1' {
                  $ServerList = "dehoiisDTK1"
                  $Version    = "Test"
                }
            '9' {
                  $ServerList = "dehoiisDTK1",
                                "dehoiisDTK2",
                                "dehoiisDTK3",
                                "dehoiisDTK4",
                                "dehoiisDTK5"
                }
          }

          if ($ServerList -ne '')
          {
            $menuDeploy = ShowMenuDeploy $AppPool
            DeployService  $ServerList $WebService $SubName $AppPool $Version $menuDeploy
          }
        }

    '3' {
          $WebService  = "WebServiceDTK"
          $AppPool     = "AppPoolDTK"
          $menuVersion = ShowMenuVersion $AppPool
          switch ($menuVersion.ToUpper())
          {
            '1' {
                  $ServerList = "dehoiisDTK1"
                  $Version    = "Test"
                }
            '9' {
              $ServerList = "dehoiisDTK1",
                            "dehoiisDTK2",
                            "dehoiisDTK3",
                            "dehoiisDTK4",
                            "dehoiisDTK5"
                }
          }

          if ($ServerList -ne '')
          {
            $menuDeploy = ShowMenuDeploy $AppPool
            DeployService  $ServerList $WebService $SubName $AppPool $Version $menuDeploy
          }
        }

    '4' {
          $WebService  = "WebServiceDTKApp"
          $AppPool     = "AppPoolDTKApp"
          $menuVersion = ShowMenuVersion $AppPool
          switch ($menuVersion.ToUpper())
          {
            '1' {
                  $ServerList = "dehoiisDTK1"
                  $Version    = "Test"
                }
            '9' {
              $ServerList = "dehoiisDTK1",
                            "dehoiisDTK2",
                            "dehoiisDTK3",
                            "dehoiisDTK4",
                            "dehoiisDTK5"
                }
          }

          if ($ServerList -ne '')
          {
            $menuDeploy = ShowMenuDeploy $AppPool
            DeployService  $ServerList $WebService $SubName $AppPool $Version $menuDeploy
          }
        }

    '6' {
          $WebService  = "WebServiceB2B"
          $SubName     = "_VCS24"
          $AppPool     = "AppPoolB2B"
          $menuVersion = ShowMenuVersion $AppPool
          switch ($menuVersion.ToUpper())
          {
            '1' {
                  $ServerList = "dehoiisDTK1"
                  $Version    = "Test"
                }
            '9' {
                  $ServerList = "dehoiisDTK1",
                                "dehoiisDTK2",
                                "dehoiisDTK3",
                                "dehoiisDTK4",
                                "dehoiisDTK5"
                }
          }

          if ($ServerList -ne '')
          {
            $menuDeploy = ShowMenuDeploy $AppPool
            DeployService  $ServerList $WebService $SubName $AppPool $Version $menuDeploy
          }
        }

    '7' {
          $WebService  = "WebServiceWLE"
          $AppPool     = "AppPoolWLE"
          $menuVersion = ShowMenuVersion $AppPool
          switch ($menuVersion.ToUpper())
          {
            '1' {
                  $ServerList = "dehoiisEN1"
                  $Version    = "Test"
                }
            '9' {
                  $ServerList = "dehoiisEN1"
                }
          }

          if ($ServerList -ne '')
          {
            $menuDeploy = ShowMenuDeploy $AppPool
            DeployService  $ServerList $WebService $SubName $AppPool $Version $menuDeploy
          }
        }

    '8' {
          $WebService  = "WebServiceAPP"
          $AppPool     = "AppPoolApp"
          $menuVersion = ShowMenuVersion $AppPool
          switch ($menuVersion.ToUpper())
          {
            '1' {
                  $ServerList = "dehoiisPAD1",
                                "dehoiisPAD2",
                                "dehoiisFR1"
                  $Version    = "Test"
                }
            '9' {
                  $ServerList = "dehoiisPAD1",
                                "dehoiisPAD2",
                                "dehoiisFR1"
                }
          }

          if ($ServerList -ne '')
          {
            $menuDeploy = ShowMenuDeploy $AppPool
            DeployService  $ServerList $WebService $SubName $AppPool $Version $menuDeploy
          }
        }
  }
}
until ($input -eq '0')
