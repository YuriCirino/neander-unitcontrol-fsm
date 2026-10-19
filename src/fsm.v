`include "neander_states.vh"

module FSM( // Sequenciador: controla em qual passo do ciclo busca/decodificação/execução se encontra
    input clk,
    input rst,
    input [3:0] opcode, // RI[7:4] - usado para decidir quantos ciclos a instrução atual precisa

    output reg [2:0] state // estado atual
    );
    parameter NOP = 4'b0000;
    parameter STA = 4'b0001;
    parameter LDA = 4'b0010;
    parameter ADD = 4'b0011;
    parameter OR  = 4'b0100;
    parameter AND = 4'b0101;
    parameter NOT = 4'b0110;
    parameter JMP = 4'b1000;
    parameter JZ  = 4'b1001;
    parameter JN  = 4'b1010;
    parameter HLT = 4'b1111;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= `FETCH_STEP_1; // Estado inicial
        end else begin
            case (state)
                //t0 - REM <- PC
                `FETCH_STEP_1: state <= `FETCH_STEP_2;
                //t1 - RDM <- MEM(REM), PC <- PC+1
                `FETCH_STEP_2: state <= `FETCH_STEP_3;
                //t2 - RI <- RDM (a partir daqui o opcode é válido)
                `FETCH_STEP_3: state <= `DECODE;
                //t3 - decodificação
                `DECODE: begin
                    case (opcode)
                        // NOP não faz nada: volta direto para a busca
                        NOP: state <= `FETCH_STEP_1;
                        // NOT e HLT não têm operando: vão direto para a execução
                        NOT, HLT: state <= `EXECUTE_STEP_1;
                        // Demais instruções (STA, LDA, ADD, OR, AND, JMP, JZ, JN) têm
                        // operando e precisam buscá-lo antes de executar.
                        // Os desvios condicionais passam por aqui mesmo quando não
                        // desviam: o operando precisa ser lido de qualquer forma para
                        // que o PC avance além dele.
                        default: state <= `FETCH_OPERAND_STEP_1;
                    endcase
                end
                //t4 - RDM <- MEM(REM), PC <- PC+1
                `FETCH_OPERAND_STEP_1: state <= `FETCH_OPERAND_STEP_2;
                //t5 - REM <- RDM (acesso a dado) ou PC <- RDM (desvio)
                `FETCH_OPERAND_STEP_2: begin
                    // Os desvios se completam neste ciclo (o PC é atualizado aqui pela
                    // unidade de controle), então não passam pela execução.
                    if (opcode == JMP || opcode == JZ || opcode == JN) begin
                        state <= `FETCH_STEP_1;
                    end else begin
                        state <= `EXECUTE_STEP_1;
                    end
                end
                //t6 - primeiro ciclo de execução
                `EXECUTE_STEP_1: begin
                    // HLT trava a FSM aqui indefinidamente (processador parado)
                    if (opcode == HLT) begin
                        state <= `EXECUTE_STEP_1;
                    end
                    // NOT termina em 1 ciclo, volta a buscar a próxima instrução
                    else if (opcode == NOT) begin
                        state <= `FETCH_STEP_1;
                    end
                    // Instruções com operando precisam do segundo ciclo de execução
                    else begin
                        state <= `EXECUTE_STEP_2;
                    end
                end
                //t7 - segundo ciclo de execução
                `EXECUTE_STEP_2: state <= `FETCH_STEP_1;
                default: state <= `FETCH_STEP_1; 
                // Estado padrão caso algo inesperado aconteça
            endcase
        end
    end

endmodule
