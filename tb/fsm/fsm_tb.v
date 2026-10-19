// ============================================================
// NEANDER - Testbench da máquina de estados
// Projeto: Processador Neander em Verilog
// Módulo: FSM
//
// Testa:
//   - A sequência de estados de cada instrução
//   - A quantidade de ciclos de cada instrução
//   - O reset assíncrono
//   - O travamento do HLT no EXECUTE_STEP_1
// ============================================================

`timescale 1ns/1ps
`include "neander_states.vh"

module fsm_tb;

    // ========================================================
    // ARQUIVO DE ONDAS
    //
    // Gera sim/fsm.vcd, para abrir no GTKWave:
    //     gtkwave sim/fsm.vcd
    //
    // O 0 no $dumpvars manda registrar o testbench inteiro,
    // incluindo os sinais internos dos modulos instanciados.
    // ========================================================

    initial begin
        $dumpfile("sim/fsm.vcd");
        $dumpvars(0, fsm_tb);
    end


    reg clk = 1'b0;
    reg rst = 1'b1;
    reg [3:0] opcode = 4'b0000;

    wire [2:0] state;

    integer erros = 0;

    // Opcodes
    localparam NOP = 4'b0000;
    localparam STA = 4'b0001;
    localparam LDA = 4'b0010;
    localparam ADD = 4'b0011;
    localparam OR_ = 4'b0100;
    localparam AND_= 4'b0101;
    localparam NOT_= 4'b0110;
    localparam JMP = 4'b1000;
    localparam JZ  = 4'b1001;
    localparam JN  = 4'b1010;
    localparam HLT = 4'b1111;

    FSM fsm_inst (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .state(state)
    );

    // Clock com período de 10 unidades de tempo
    always #5 clk = ~clk;

    // Converte o código do estado no seu nome, para o log
    function [8*16:1] nome_estado;
        input [2:0] s;
        begin
            case (s)
                `FETCH_STEP_1:         nome_estado = "t0 FETCH_1      ";
                `FETCH_STEP_2:         nome_estado = "t1 FETCH_2      ";
                `FETCH_STEP_3:         nome_estado = "t2 FETCH_3      ";
                `DECODE:               nome_estado = "t3 DECODE       ";
                `FETCH_OPERAND_STEP_1: nome_estado = "t4 FETCH_OPER_1 ";
                `FETCH_OPERAND_STEP_2: nome_estado = "t5 FETCH_OPER_2 ";
                `EXECUTE_STEP_1:       nome_estado = "t6 EXECUTE_1    ";
                `EXECUTE_STEP_2:       nome_estado = "t7 EXECUTE_2    ";
                default:               nome_estado = "?? DESCONHECIDO ";
            endcase
        end
    endfunction

    // Confere o estado atual e avança para o meio do ciclo seguinte.
    // A checagem é feita na descida do clock, quando o estado já está estável.
    task passo;
        input [2:0] esperado;
        begin
            if (state !== esperado) begin
                erros = erros + 1;
                $display("    ERRO   esperado: %0s | obtido: %0s",
                         nome_estado(esperado), nome_estado(state));
            end
            else begin
                $display("    ok     %0s", nome_estado(state));
            end
            @(negedge clk);
        end
    endtask

    // Prepara o início de uma instrução: o opcode fica válido a partir do t3,
    // mas nenhum estado antes disso consulta o opcode, então pode ser
    // colocado já no t0.
    task inicia;
        input [3:0] op;
        input [8*12:1] rotulo;
        begin
            $display("\n-- %0s --", rotulo);
            opcode = op;
        end
    endtask

    // Percorre os 4 primeiros estados, comuns a todas as instruções
    task busca_e_decodificacao;
        begin
            passo(`FETCH_STEP_1);
            passo(`FETCH_STEP_2);
            passo(`FETCH_STEP_3);
            passo(`DECODE);
        end
    endtask

    initial begin
        $display("============================================================");
        $display(" Testbench da FSM");
        $display("============================================================");

        // Reset assíncrono: o estado deve ir para FETCH_STEP_1 imediatamente
        #1;
        if (state !== `FETCH_STEP_1) begin
            erros = erros + 1;
            $display("ERRO: reset nao levou a FSM para FETCH_STEP_1");
        end

        @(negedge clk); // meio do ciclo t0
        rst = 1'b0;

        // NOP: 4 ciclos, nao executa nada
        inicia(NOP, "NOP        ");
        busca_e_decodificacao;

        // Instrucoes com operando e 2 ciclos de execucao: 8 ciclos
        inicia(LDA, "LDA        ");
        busca_e_decodificacao;
        passo(`FETCH_OPERAND_STEP_1);
        passo(`FETCH_OPERAND_STEP_2);
        passo(`EXECUTE_STEP_1);
        passo(`EXECUTE_STEP_2);

        inicia(STA, "STA        ");
        busca_e_decodificacao;
        passo(`FETCH_OPERAND_STEP_1);
        passo(`FETCH_OPERAND_STEP_2);
        passo(`EXECUTE_STEP_1);
        passo(`EXECUTE_STEP_2);

        inicia(ADD, "ADD        ");
        busca_e_decodificacao;
        passo(`FETCH_OPERAND_STEP_1);
        passo(`FETCH_OPERAND_STEP_2);
        passo(`EXECUTE_STEP_1);
        passo(`EXECUTE_STEP_2);

        inicia(OR_, "OR         ");
        busca_e_decodificacao;
        passo(`FETCH_OPERAND_STEP_1);
        passo(`FETCH_OPERAND_STEP_2);
        passo(`EXECUTE_STEP_1);
        passo(`EXECUTE_STEP_2);

        inicia(AND_, "AND        ");
        busca_e_decodificacao;
        passo(`FETCH_OPERAND_STEP_1);
        passo(`FETCH_OPERAND_STEP_2);
        passo(`EXECUTE_STEP_1);
        passo(`EXECUTE_STEP_2);

        // NOT nao tem operando e executa em 1 ciclo: 5 ciclos
        inicia(NOT_, "NOT        ");
        busca_e_decodificacao;
        passo(`EXECUTE_STEP_1);

        // Desvios: terminam no t5, sem passar pela execucao (6 ciclos).
        // A FSM nao consulta as flags: quem decide se o PC e carregado e a
        // unidade de controle, entao o caminho e o mesmo com desvio ou sem.
        inicia(JMP, "JMP        ");
        busca_e_decodificacao;
        passo(`FETCH_OPERAND_STEP_1);
        passo(`FETCH_OPERAND_STEP_2);

        inicia(JZ, "JZ         ");
        busca_e_decodificacao;
        passo(`FETCH_OPERAND_STEP_1);
        passo(`FETCH_OPERAND_STEP_2);

        inicia(JN, "JN         ");
        busca_e_decodificacao;
        passo(`FETCH_OPERAND_STEP_1);
        passo(`FETCH_OPERAND_STEP_2);

        // HLT: trava no EXECUTE_STEP_1 indefinidamente
        inicia(HLT, "HLT        ");
        busca_e_decodificacao;
        passo(`EXECUTE_STEP_1);
        passo(`EXECUTE_STEP_1);
        passo(`EXECUTE_STEP_1);

        // O reset deve tirar a FSM do travamento do HLT
        $display("\n-- reset durante o HLT --");
        rst = 1'b1;
        #1;
        if (state !== `FETCH_STEP_1) begin
            erros = erros + 1;
            $display("    ERRO   reset nao tirou a FSM do HLT");
        end
        else begin
            $display("    ok     reset levou a FSM de volta para FETCH_STEP_1");
        end

        $display("\n============================================================");
        if (erros == 0)
            $display(" RESULTADO: todos os testes passaram");
        else
            $display(" RESULTADO: %0d erro(s) encontrado(s)", erros);
        $display("============================================================");

        $finish;
    end

endmodule
