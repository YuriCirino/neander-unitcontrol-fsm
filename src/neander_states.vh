// ============================================================
// NEANDER - Estados da FSM (fonte única de verdade)
// Projeto: Processador Neander em Verilog
//
// Compartilhado entre fsm.v (sequenciador) e unit_control.v
// (decodificador), para evitar que as duas codificações
// de estado fiquem dessincronizadas.
// ============================================================

`define FETCH_STEP_1         3'b000 // Estado de busca 1: REM <- PC, PC <- PC+1
`define FETCH_STEP_2         3'b001 // Estado de busca 2: RDM <- MEM(REM)
`define FETCH_STEP_3         3'b111 // Estado de busca 3: RI <- RDM (um ciclo depois de RDM ser carregado)
`define DECODE               3'b010 // Estado de decodificação
`define FETCH_OPERAND_STEP_2 3'b011 // Estado de busca do operando, segundo passo
`define FETCH_OPERAND_STEP_1 3'b100 // Estado de busca do operando, primeiro passo
`define EXECUTE_STEP_1       3'b101 // Estado de execução, primeiro passo
`define EXECUTE_STEP_2       3'b110 // Estado de execução, segundo passo
