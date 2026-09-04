module FSM( // Sequenciador: controla em qual passo do ciclo busca/decodificação/execução se encontra 
    input clk,
    input rst,
    input [3:0] opcode, // RI[7:4] - usado para decidir quantos ciclos a instrução atual precisa

    output reg [2:0] state // estado atual
    );
    parameter FETCH_STEP_1 = 3'b000; // Estado de busca 1
    parameter FETCH_STEP_2 = 3'b001; // Estado de busca 2
    parameter DECODE = 3'b010; // Estado de decodificação
    parameter FETCH_OPERAND_STEP_2 = 3'b011; // Estado de busca do operando, segundo passo
    parameter FETCH_OPERAND_STEP_1 = 3'b100; // Estado de busca do operando, primeiro passo
    parameter EXECUTE_STEP_1 = 3'b101; // Estado de execução, primeiro passo
    parameter EXECUTE_STEP_2 = 3'b110; // Estado de execução, segundo passo
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
            state <= FETCH_STEP_1; // Estado inicial
        end else begin
            case (state)
                FETCH_STEP_1: state <= FETCH_STEP_2; // Transição do estado de busca 1 para busca 2
                FETCH_STEP_2: state <= DECODE; // Transição do estado de busca 2 para decodificação
                DECODE: begin
                    // NOP não precisa executar nada: volta direto pra busca
                    if (opcode == NOP) begin
                        state <= FETCH_STEP_1;
                    end
                    // NOT e HLT não têm operando: executam em 1 ciclo (EXECUTE_STEP_1)
                    else if (opcode == NOT || opcode == HLT) begin
                        state <= EXECUTE_STEP_1;
                    end
                    // Demais instruções têm operando: precisam buscá-lo antes de executar
                    else begin
                        state <= FETCH_OPERAND_STEP_1;
                    end
                end
                FETCH_OPERAND_STEP_1: state <= FETCH_OPERAND_STEP_2; // Transição para o segundo passo de busca do operando
                FETCH_OPERAND_STEP_2: state <= EXECUTE_STEP_1; // Após buscar o operando, vai para execução
                EXECUTE_STEP_1: begin
                    // HLT trava a FSM aqui indefinidamente (processador parado)
                    if (opcode == HLT) begin
                        state <= EXECUTE_STEP_1;
                    end
                    // NOT termina em 1 ciclo, volta a buscar a próxima instrução
                    else if (opcode == NOT) begin
                        state <= FETCH_STEP_1;
                    end
                    // Instruções com operando (chegaram via FETCH_OPERAND) precisam do segundo ciclo de execução
                    else begin
                        state <= EXECUTE_STEP_2;
                    end
                end
                EXECUTE_STEP_2: state <= FETCH_STEP_1; // Após o segundo ciclo de execução, retorna ao início
                default: state <= FETCH_STEP_1; // Estado padrão caso algo inesperado aconteça
            endcase
        end
    end

endmodule
