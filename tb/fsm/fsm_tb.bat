@echo off
REM ============================================================
REM  NEANDER - Simulacao do testbench da FSM
REM
REM  Uso:
REM    - duplo clique neste arquivo, ou
REM    - tb\fsm\fsm_tb.bat            (de qualquer pasta)
REM    - tb\fsm\fsm_tb.bat nopause    (sem a pausa no final)
REM
REM  Compila tb\fsm\fsm_tb.v junto com os fontes do modulo e roda
REM  a simulacao. O executavel gerado vai para sim\sim_fsm.
REM
REM  Gera:
REM    sim\sim_fsm     executavel da simulacao
REM    sim\fsm.vcd     formas de onda, para abrir no GTKWave
REM ============================================================

setlocal

REM Nome do modulo e fontes de src\ que este testbench precisa.
REM Se o modulo passar a depender de outro arquivo, some ele aqui.
set "NOME=fsm"
set "FONTES=src\fsm.v"

REM ---------- daqui para baixo e igual em todos os scripts ----------
set "PAUSA=1"
if /i "%~1"=="nopause" set "PAUSA=0"

REM Vai para a raiz do projeto (duas pastas acima desta)
set "RAIZ=%~dp0..\.."
pushd "%RAIZ%"
set "CODIGO=0"

where iverilog >nul 2>&1
if errorlevel 1 (
    echo [ERRO] iverilog nao encontrado no PATH.
    echo        Instale o Icarus Verilog e adicione a pasta bin dele ao PATH
    echo        do Windows. Exemplo: C:\iverilog\bin
    set "CODIGO=1"
    goto :fim
)

if not exist "sim" mkdir "sim"

echo ============================================================
echo  Simulando: %NOME%
echo ============================================================
echo.

REM -I src faz o iverilog encontrar o neander_states.vh dos includes
iverilog -I src -o "sim\sim_%NOME%" "tb\%NOME%\%NOME%_tb.v" %FONTES%
if errorlevel 1 (
    echo.
    echo [ERRO] Falha ao compilar o testbench de %NOME%
    set "CODIGO=1"
    goto :fim
)

vvp "sim\sim_%NOME%"
if errorlevel 1 set "CODIGO=1"

:fim
popd
if "%PAUSA%"=="0" exit /b %CODIGO%
REM Pausa apenas quando o script foi aberto com duplo clique
echo %CMDCMDLINE% | find /i "%~nx0" >nul
if not errorlevel 1 pause
exit /b %CODIGO%
