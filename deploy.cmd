@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

:: ----------------------
:: KUDU Deployment Script
:: Version: 0.1.13
:: ----------------------

:: Setup
:: -----

setlocal enabledelayedexpansion

SET ARTIFACTS=%~dp0%..\artifacts

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
  SET DEPLOYMENT_TARGET=%HOME%\site\wwwroot
)

IF NOT DEFINED NEXT_MANIFEST_PATH (
  SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

  IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
    SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest
  )
)

IF NOT DEFINED HEXO_PATH (
   echo Setting HEXO_PATH to %HOME%\npm_tools\hexo.cmd
   set HEXO_PATH="%HOME%\npm_tools\hexo.cmd"
)
goto Deployment

:::::::::::::::
:: Deployment
:: ----------

:Deployment
echo Handling Hexo deployment.

IF NOT EXIST %HEXO_PATH% (
  echo Hexo CLI isn't installed. Running 'npm install hexo-cli -g'
  call :ExecuteCmd mkdir "%HOME%\npm_tools"
  IF !ERRORLEVEL! NEQ 0 goto error

  call :ExecuteCmd npm config set prefix "%HOME%\npm_tools"
  IF !ERRORLEVEL! NEQ 0 goto error

  call :ExecuteCmd npm install -g hexo-cli
  IF !ERRORLEVEL! NEQ 0 goto error
)

echo Running 'npm install --production'
call :ExecuteCmd npm install --production
IF !ERRORLEVEL! NEQ 0 goto error

echo Running 'hexo generate'
call :ExecuteCmd !HEXO_PATH! generate
IF !ERRORLEVEL! NEQ 0 goto error

echo Copying static content to site root
call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "public" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"
IF !ERRORLEVEL! NEQ 0 goto error

goto end

:: Execute command routine that will echo out when error
:ExecuteCmd
setlocal
set _CMD_=%*
call %_CMD_%
if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
exit /b %ERRORLEVEL%

:error
endlocal
echo An error has occurred during web site deployment.
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
endlocal
echo Finished successfully.
