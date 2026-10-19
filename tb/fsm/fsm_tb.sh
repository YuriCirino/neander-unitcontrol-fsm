#!/usr/bin/env bash
# ============================================================
#  NEANDER - Simulacao do testbench da FSM
#
#  Uso:
#    ./tb/fsm/fsm_tb.sh        (de qualquer pasta do projeto)
#
#  Versao Linux/macOS do fsm_tb.bat. Compila tb/fsm/fsm_tb.v
#  junto com os fontes do modulo e roda a simulacao.
#
#  Gera:
#    sim/sim_fsm     executavel da simulacao
#    sim/fsm.vcd     formas de onda, para abrir no GTKWave
# ============================================================

set -u

# Nome do modulo e fontes de src/ que este testbench precisa.
# Se o modulo passar a depender de outro arquivo, some ele aqui.
NOME="fsm"
FONTES="src/fsm.v"

# ---------- daqui para baixo e igual em todos os scripts ----------

# Vai para a raiz do projeto (duas pastas acima desta)
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$RAIZ" || exit 1

if ! command -v iverilog > /dev/null 2>&1; then
    echo "[ERRO] iverilog nao encontrado no PATH."
    echo "       Debian/Ubuntu:  sudo apt install iverilog gtkwave"
    echo "       Fedora:         sudo dnf install iverilog gtkwave"
    echo "       macOS:          brew install icarus-verilog"
    exit 1
fi

mkdir -p sim

echo "============================================================"
echo " Simulando: $NOME"
echo "============================================================"
echo

# -I src faz o iverilog encontrar o neander_states.vh dos includes
if ! iverilog -I src -o "sim/sim_$NOME" "tb/$NOME/${NOME}_tb.v" $FONTES; then
    echo
    echo "[ERRO] Falha ao compilar o testbench de $NOME"
    exit 1
fi

vvp "sim/sim_$NOME"
