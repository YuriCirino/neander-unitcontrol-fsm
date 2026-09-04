module Unit_Control( // Unidade de controle completa: FSM (sequenciador) + decodificador combinacional
    input clk,
    input rst,
    input [3:0] opcode, // código de operação (RI[7:4])
    input Z, // Flag de zero
    input N, // Flag de negativo

    output reg carga_rem, // Sinal de carga do registrador de memória
    output reg carga_rdm, // Sinal de carga do registrador de dados da memória
    output reg incrementa_pc, // Sinal de incremento do contador de programa
    output reg [1:0] sel_ula, // Sinal de seleção da ULA
    output reg carga_ri, // Sinal de carga do registrador de instrução
    output reg sel_rem, // Sinal de seleção do registrador de memória
    output reg sel_rdm, // Sinal de seleção do registrador de dados da memória
    output reg read, // Sinal de leitura da memória
    output reg write, // Sinal de escrita na memória
    output reg carga_ac, // Sinal de carga do acumulador
    output reg carga_pc, // Sinal de carga do contador de programa
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

    parameter FETCH_STEP_1 = 3'b000; // Estado de busca 1
    parameter FETCH_STEP_2 = 3'b001; // Estado de busca 2
    parameter DECODE = 3'b010; // Estado de decodificação
    parameter EXECUTE = 3'b011; // Estado de execução
    parameter FETCH_OPERAND_STEP_1 = 3'b100; // Estado de busca do operando, primeiro passo
    parameter FETCH_OPERAND_STEP_2 = 3'b101; // Estado de busca do operando, segundo passo

    wire [2:0] state; // sinal interno: liga a FSM ao decodificador, não faz parte da interface pública da UC

    FSM fsm_inst (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .state(state)
    );

    always @(*) begin
        // Valores padrão: evita inferência de latch para sinais não usados no estado/opcode atual
        carga_rem = 1'b0;
        carga_rdm = 1'b0;
        incrementa_pc = 1'b0;
        sel_ula = 2'b00;
        carga_ri = 1'b0;
        sel_rem = 1'b0;
        sel_rdm = 1'b0;
        read = 1'b0;
        write = 1'b0;
        carga_ac = 1'b0;
        carga_pc = 1'b0;
        goto0 = 1'b0;

        case (state)
            FETCH_STEP_1: begin
                // REM <- PC
                sel_rem = 1'b0;
                carga_rem = 1'b1;
                read = 1'b1;
            end
            FETCH_STEP_2: begin
                // RI <- RDM
                sel_rdm = 1'b0;
                carga_rdm = 1'b1;
                carga_ri = 1'b1;
            end
            DECODE: begin
                // TODO: sinais do estado de decodificação (se houver algum além da transição na FSM)
            end
            FETCH_OPERAND_STEP_1: begin
                // TODO: busca do segundo byte (endereço do operando) - primeiro passo
            end
            FETCH_OPERAND_STEP_2: begin
                // TODO: busca do segundo byte (endereço do operando) - segundo passo
            end
            EXECUTE: begin
                case (opcode)
                    NOP: begin
                        incrementa_pc = 1'b1;
                    end
                    STA: begin
                        // TODO
                    end
                    LDA: begin
                        // TODO
                    end
                    ADD: begin
                        // TODO
                    end
                    OR: begin
                        // TODO
                    end
                    AND: begin
                        // TODO
                    end
                    NOT: begin
                        // TODO
                    end
                    JMP: begin
                        // TODO
                    end
                    JZ: begin
                        // TODO
                    end
                    JN: begin
                        // TODO
                    end
                    HLT: begin
                        // TODO
                    end
                endcase
            end
            default: begin
                // Estado inesperado: mantém tudo em 0 (já garantido pelos valores padrão acima)
            end
        endcase
    end

endmodule
