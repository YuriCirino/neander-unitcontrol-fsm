module Unit_Control( // Decodificador: combinacional, decide os sinais de controle a partir do estado atual + opcode
    input [3:0] state, // estado atual, vindo da FSM (mesma largura usada em fsm.v)
    input [3:0] opcode, // código de operação (RI[7:4])
    input Z, // Flag de zero
    input N, // Flag de negativo

    output reg carga_rem, // Sinal de carga do registrador de memória
    output reg carga_rdm, // Sinal de carga do registrador de dados da memória
    output reg incrementa_pc, // Sinal de incremento do contador de programa
    output reg [1:0] sel_ula, // Sinal de seleção da ULA
    output reg caga_ri, // Sinal de carga do registrador de instrução
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
    parameter OR = 4'b0100;
    parameter AND = 4'b0101;
    parameter NOT = 4'b0110;
    parameter JMP = 4'b1000;
    parameter JZ = 4'b1001;
    parameter JN = 4'b1010;
    parameter HLT = 4'b1111;
    

    // TODO: always @(*) combinacional que decide os sinais de controle
    // a partir de state (+ opcode para os estados de execução, + Z/N para os saltos condicionais)

endmodule
