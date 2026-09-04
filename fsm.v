module FSM( // Sequenciador: controla em qual passo do ciclo busca/decodificação/execução estamos
    input clk,
    input rst,
    input [3:0] opcode, // RI[7:4] - usado para decidir quantos ciclos a instrução atual precisa

    output reg [2:0] state // estado atual (ajuste a largura conforme o número de estados que você definir)
    );
    parameter FETCH_STEP_1 = 4'b000; // Estado de busca 1
    parameter FETCH_STEP_2 = 4'b001; // Estado de busca 2
    parameter DECODE = 4'b010; // Estado de decodificação
    parameter EXECUTE = 4'b011; // Estado de execução 1
    parameter FETCH_OPERAND_STEP_1 = 4'b100; // Estado de busca do operando, primeiro passo
    parameter FETCH_OPERAND_STEP_2 = 4'b101; // Estado de busca do operando, segundo passo

    // TODO: definir os parâmetros de estado (ex: BUSCA1, BUSCA2, DECODE, EXEC1, EXEC2...)

    // TODO: always @(posedge clk or posedge rst) com a lógica de transição de estados

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= FETCH_STEP_1; // Estado inicial (ex: BUSCA1)
        end else begin
            case (state)
                FETCH_STEP_1: state <= FETCH_STEP_2; // Transição do estado de busca 1 para busca 2
                FETCH_STEP_2: state <= DECODE; // Transição do estado de busca 2 para decodificação
                DECODE: begin
                    // Decisão baseada no opcode para determinar o próximo estado
                    if (opcode == 4'b0110 || opcode == 4'b1111)begin
                        state <= EXECUTE; // Transição para execução se não for uma instrução de salto ou HLT
                    end else begin 
                        state <= FETCH_OPERAND_STEP_1; // Transição para busca do operando se for uma instrução de salto ou HLT
                    end
                end
                EXECUTE: state <= FETCH_STEP_1; // Após execução, retorna ao início
                FETCH_OPERAND_STEP_1: state <= FETCH_OPERAND_STEP_2; // Transição para o segundo passo de busca do operando
                FETCH_OPERAND_STEP_2: state <= EXECUTE; // Após buscar o operando, vai para execução
                default: state <= FETCH_STEP_1; // Estado padrão caso algo inesperado aconteça
            endcase
        end

endmodule
