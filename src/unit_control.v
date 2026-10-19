`include "neander_states.vh"

module Unit_Control( // Unidade de controle completa: FSM (sequenciador) + decodificador combinacional
    input clk,
    input rst,
    input [3:0] opcode, // código de operação (RI[7:4])
    input Z, // Flag de zero
    input N, // Flag de negativo

    output reg carga_rem, // Sinal de carga do registrador de endereço da memória
    output reg carga_rdm, // Sinal de carga do registrador de dados da memória
    output reg incrementa_pc, // Sinal de incremento do contador de programa
    output reg [2:0] sel_ula, // Sinal de seleção da operação da ULA
    output reg carga_ri, // Sinal de carga do registrador de instrução
    output reg sel_rem, // Seleção da entrada do REM: 0 = PC, 1 = RDM
    output reg sel_rdm, // Seleção da entrada do RDM: 0 = memória, 1 = AC
    output reg read, // Sinal de leitura da memória
    output reg write, // Sinal de escrita na memória
    output reg carga_ac, // Sinal de carga do acumulador
    output reg carga_pc, // Sinal de carga do contador de programa (PC <- RDM)
    output reg carga_nz, // Sinal de carga das flags de zero e negativo
    output reg goto0 // Sinal de salto para o endereço 0
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

    // Operações da ULA (conforme ula.v)
    parameter ULA_ADD = 3'b000;
    parameter ULA_AND = 3'b001;
    parameter ULA_OR  = 3'b010;
    parameter ULA_NOT = 3'b011;
    parameter ULA_ID  = 3'b100; // resultado = Y (usado pelo LDA: AC <- RDM)

    wire [2:0] state; // sinal interno: liga a FSM ao decodificador, não faz parte da interface pública da UC

    FSM fsm_inst (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .state(state)
    );

    always @(*) begin
        // Valores padrão: evita bugs
        carga_rem = 1'b0;
        carga_rdm = 1'b0;
        incrementa_pc = 1'b0;
        sel_ula = ULA_ADD;
        carga_ri = 1'b0;
        sel_rem = 1'b0;
        sel_rdm = 1'b0;
        read = 1'b0;
        write = 1'b0;
        carga_ac = 1'b0;
        carga_pc = 1'b0;
        carga_nz = 1'b0;
        goto0 = 1'b0;

        case (state)
            `FETCH_STEP_1: begin
                //t0
                // REM <- PC
                sel_rem = 1'b0;
                carga_rem = 1'b1;
            end
            `FETCH_STEP_2: begin
                //t1
                // RDM <- MEM(REM) e PC <- PC+1
                sel_rdm = 1'b0;
                read = 1'b1;
                carga_rdm = 1'b1;
                incrementa_pc = 1'b1; // Incrementa PC para apontar para o próximo byte
            end
            `FETCH_STEP_3: begin
                //t2
                // RI <- RDM (um ciclo depois de RDM ser carregado, pra pegar o valor certo)
                carga_ri = 1'b1;
            end
            `DECODE: begin
                //t3
                case (opcode)
                    NOP, NOT, HLT: begin
                        // Não têm operando: nada a fazer neste ciclo
                    end
                    default: begin
                        // Adianta REM <- PC: o PC já aponta para o byte do operando
                        sel_rem = 1'b0;
                        carga_rem = 1'b1;
                    end
                endcase
            end
            `FETCH_OPERAND_STEP_1: begin
                //t4
                // RDM <- MEM(REM): busca o operando (endereço do dado, ou destino do desvio)
                sel_rdm = 1'b0;
                read = 1'b1;
                carga_rdm = 1'b1;
                // PC <- PC+1 em todas as instruções com operando, inclusive nos desvios:
                // se o desvio for tomado o carga_pc do próximo estado sobrescreve o PC;
                // se não for, o PC precisa mesmo passar por cima do byte do operando.
                incrementa_pc = 1'b1;
            end
            `FETCH_OPERAND_STEP_2: begin
                //t5
                case (opcode)
                    JMP: begin
                        // Desvio incondicional: PC <- RDM
                        carga_pc = 1'b1;
                    end
                    JZ: begin
                        // Desvia apenas se o resultado anterior foi zero
                        if (Z == 1'b1) begin
                            carga_pc = 1'b1;
                        end
                    end
                    JN: begin
                        // Desvia apenas se o resultado anterior foi negativo
                        if (N == 1'b1) begin
                            carga_pc = 1'b1;
                        end
                    end
                    default: begin
                        // STA, LDA, ADD, OR, AND: REM <- RDM (endereço do dado)
                        sel_rem = 1'b1;
                        carga_rem = 1'b1;
                    end
                endcase
            end
            `EXECUTE_STEP_1: begin
                //t6
                case (opcode)
                    STA: begin
                        // RDM <- AC (prepara o dado que será escrito na memória)
                        sel_rdm = 1'b1;
                        carga_rdm = 1'b1;
                    end
                    LDA, ADD, OR, AND: begin
                        // RDM <- MEM(REM): agora sim busca o dado apontado pelo operando
                        sel_rdm = 1'b0;
                        read = 1'b1;
                        carga_rdm = 1'b1;
                    end
                    NOT: begin
                        // AC <- NOT(AC); atualiza N e Z (não usa a memória)
                        sel_ula = ULA_NOT;
                        carga_ac = 1'b1;
                        carga_nz = 1'b1;
                    end
                    default: begin
                        // HLT e opcodes inválidos: nenhum sinal ativo
                    end
                endcase
            end
            `EXECUTE_STEP_2: begin
                //t7
                case (opcode)
                    STA: begin
                        // MEM(REM) <- RDM
                        write = 1'b1;
                    end
                    LDA: begin
                        // AC <- RDM; atualiza N e Z
                        sel_ula = ULA_ID;
                        carga_ac = 1'b1;
                        carga_nz = 1'b1;
                    end
                    ADD: begin
                        // AC <- AC + RDM; atualiza N e Z
                        sel_ula = ULA_ADD;
                        carga_ac = 1'b1;
                        carga_nz = 1'b1;
                    end
                    OR: begin
                        // AC <- AC OR RDM; atualiza N e Z
                        sel_ula = ULA_OR;
                        carga_ac = 1'b1;
                        carga_nz = 1'b1;
                    end
                    AND: begin
                        // AC <- AC AND RDM; atualiza N e Z
                        sel_ula = ULA_AND;
                        carga_ac = 1'b1;
                        carga_nz = 1'b1;
                    end
                    default: begin
                        // Opcodes inválidos: nenhum sinal ativo
                    end
                endcase
            end
            default: begin
                // Estado inesperado: mantém tudo em 0 (já garantido pelos valores padrão acima)
            end
        endcase
    end

endmodule
