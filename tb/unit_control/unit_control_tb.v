// ============================================================
// NEANDER - Testbench da unidade de controle
// Projeto: Processador Neander em Verilog
// Módulo: Unit_Control
//
// Testa, para cada uma das 11 instruções, os sinais de controle
// gerados em cada ciclo, conforme a tabela de transferências:
//   - REM <- PC / REM <- RDM
//   - RDM <- MEM(REM) / RDM <- AC
//   - RI <- RDM
//   - PC <- PC+1 / PC <- RDM
//   - Operações da ULA e atualização das flags N e Z
//
// Nos desvios condicionais (JZ e JN) testa os dois casos:
//   com a flag ativa (desvia) e com a flag inativa (não desvia).
// ============================================================

`timescale 1ns/1ps
`include "neander_states.vh"

module unit_control_tb;

    // ========================================================
    // ARQUIVO DE ONDAS
    //
    // Gera sim/unit_control.vcd, para abrir no GTKWave:
    //     gtkwave sim/unit_control.vcd
    //
    // O 0 no $dumpvars manda registrar o testbench inteiro,
    // incluindo os sinais internos dos modulos instanciados.
    // ========================================================

    initial begin
        $dumpfile("sim/unit_control.vcd");
        $dumpvars(0, unit_control_tb);
    end


    reg clk = 1'b0;
    reg rst = 1'b1;
    reg [3:0] opcode = 4'b0000;
    reg Z = 1'b0;
    reg N = 1'b0;

    wire carga_rem;
    wire carga_rdm;
    wire incrementa_pc;
    wire [2:0] sel_ula;
    wire carga_ri;
    wire sel_rem;
    wire sel_rdm;
    wire read;
    wire write;
    wire carga_ac;
    wire carga_pc;
    wire carga_nz;
    wire goto0;

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

    // Operações da ULA (conforme ula.v)
    localparam ULA_ADD = 3'b000;
    localparam ULA_AND = 3'b001;
    localparam ULA_OR  = 3'b010;
    localparam ULA_NOT = 3'b011;
    localparam ULA_ID  = 3'b100;

    Unit_Control ucut (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .Z(Z),
        .N(N),
        .carga_rem(carga_rem),
        .carga_rdm(carga_rdm),
        .incrementa_pc(incrementa_pc),
        .sel_ula(sel_ula),
        .carga_ri(carga_ri),
        .sel_rem(sel_rem),
        .sel_rdm(sel_rdm),
        .read(read),
        .write(write),
        .carga_ac(carga_ac),
        .carga_pc(carga_pc),
        .carga_nz(carga_nz),
        .goto0(goto0)
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

    // Imprime os sinais do ciclo atual e avança para o meio do ciclo seguinte
    task passo;
        begin
            $display("    %0s cREM=%b sREM=%b | cRDM=%b sRDM=%b | rd=%b wr=%b | cRI=%b | incPC=%b cPC=%b | cAC=%b cNZ=%b ula=%b",
                     nome_estado(ucut.state), carga_rem, sel_rem, carga_rdm, sel_rdm,
                     read, write, carga_ri, incrementa_pc, carga_pc,
                     carga_ac, carga_nz, sel_ula);
            @(negedge clk);
        end
    endtask

    // Registra um erro se a condição esperada não for verdadeira
    task verifica;
        input condicao;
        input [8*52:1] descricao;
        begin
            if (condicao !== 1'b1) begin
                erros = erros + 1;
                $display("    ERRO: %0s", descricao);
            end
        end
    endtask

    task inicia;
        input [3:0] op;
        input [8*14:1] rotulo;
        begin
            $display("\n-- %0s --", rotulo);
            opcode = op;
        end
    endtask

    // t0 a t3: busca e decodificação, iguais para todas as instruções.
    // O parâmetro diz se a instrução tem operando (nesse caso o t3 já
    // adianta REM <- PC).
    task busca_e_decodificacao;
        input tem_operando;
        begin
            // t0: REM <- PC
            verifica(carga_rem === 1'b1 && sel_rem === 1'b0, "t0: REM <- PC");
            passo;
            // t1: RDM <- MEM(REM) e PC <- PC+1
            verifica(read === 1'b1 && carga_rdm === 1'b1 && sel_rdm === 1'b0,
                     "t1: RDM <- MEM(REM)");
            verifica(incrementa_pc === 1'b1, "t1: PC <- PC+1");
            passo;
            // t2: RI <- RDM
            verifica(carga_ri === 1'b1, "t2: RI <- RDM");
            verifica(carga_rdm === 1'b0, "t2: RDM nao pode ser carregado junto com o RI");
            passo;
            // t3: adianta REM <- PC apenas nas instrucoes com operando
            if (tem_operando)
                verifica(carga_rem === 1'b1 && sel_rem === 1'b0, "t3: REM <- PC");
            else
                verifica(carga_rem === 1'b0, "t3: instrucao sem operando nao carrega o REM");
            passo;
        end
    endtask

    // t4 e t5 das instrucoes que acessam dado na memoria (STA, LDA, ADD, OR, AND)
    task busca_operando_dado;
        begin
            // t4: RDM <- MEM(REM) (endereco do dado) e PC <- PC+1
            verifica(read === 1'b1 && carga_rdm === 1'b1 && sel_rdm === 1'b0,
                     "t4: RDM <- MEM(REM)");
            verifica(incrementa_pc === 1'b1, "t4: PC <- PC+1");
            passo;
            // t5: REM <- RDM
            verifica(carga_rem === 1'b1 && sel_rem === 1'b1, "t5: REM <- RDM");
            verifica(carga_pc === 1'b0, "t5: instrucao de dado nao pode carregar o PC");
            passo;
        end
    endtask

    // Operacoes da ULA que leem o dado da memoria: LDA, ADD, OR, AND
    task operacao_ula;
        input [3:0] op;
        input [2:0] ula_esperada;
        input [8*14:1] rotulo;
        begin
            inicia(op, rotulo);
            busca_e_decodificacao(1'b1);
            busca_operando_dado;
            // t6: RDM <- MEM(REM), agora o dado em si
            verifica(read === 1'b1 && carga_rdm === 1'b1 && sel_rdm === 1'b0,
                     "t6: RDM <- MEM(REM) (dado)");
            passo;
            // t7: AC <- resultado da ULA, atualizando N e Z
            verifica(carga_ac === 1'b1 && carga_nz === 1'b1, "t7: AC e flags atualizados");
            verifica(sel_ula === ula_esperada, "t7: operacao da ULA incorreta");
            passo;
        end
    endtask

    // Desvios: verifica se o PC e carregado (ou nao) conforme a condicao
    task desvio;
        input [3:0] op;
        input desvia;
        input [8*14:1] rotulo;
        begin
            inicia(op, rotulo);
            busca_e_decodificacao(1'b1);
            // t4: busca o endereco de destino
            verifica(read === 1'b1 && carga_rdm === 1'b1, "t4: RDM <- MEM(REM)");
            verifica(incrementa_pc === 1'b1,
                     "t4: PC <- PC+1 (necessario quando o desvio nao e tomado)");
            passo;
            // t5: PC <- RDM apenas se a condicao for verdadeira
            if (desvia)
                verifica(carga_pc === 1'b1, "t5: deveria desviar (PC <- RDM)");
            else
                verifica(carga_pc === 1'b0, "t5: nao deveria desviar");
            verifica(carga_rem === 1'b0, "t5: desvio nao carrega o REM");
            passo;
        end
    endtask

    initial begin
        $display("============================================================");
        $display(" Testbench da Unidade de Controle");
        $display("============================================================");

        @(negedge clk); // meio do ciclo t0
        rst = 1'b0;

        // ---------------- NOP ----------------
        inicia(NOP, "NOP          ");
        busca_e_decodificacao(1'b0);

        // ---------------- LDA, ADD, OR, AND ----------------
        operacao_ula(LDA,  ULA_ID,  "LDA          ");
        operacao_ula(ADD,  ULA_ADD, "ADD          ");
        operacao_ula(OR_,  ULA_OR,  "OR           ");
        operacao_ula(AND_, ULA_AND, "AND          ");

        // ---------------- STA ----------------
        inicia(STA, "STA          ");
        busca_e_decodificacao(1'b1);
        busca_operando_dado;
        // t6: RDM <- AC (prepara o dado a ser escrito)
        verifica(sel_rdm === 1'b1 && carga_rdm === 1'b1, "t6: RDM <- AC");
        verifica(read === 1'b0, "t6: STA nao le a memoria");
        passo;
        // t7: MEM(REM) <- RDM
        verifica(write === 1'b1, "t7: escrita na memoria");
        verifica(carga_ac === 1'b0, "t7: STA nao altera o AC");
        passo;

        // ---------------- NOT ----------------
        inicia(NOT_, "NOT          ");
        busca_e_decodificacao(1'b0);
        // t6: AC <- NOT(AC), atualizando N e Z
        verifica(sel_ula === ULA_NOT, "t6: operacao NOT na ULA");
        verifica(carga_ac === 1'b1 && carga_nz === 1'b1, "t6: AC e flags atualizados");
        verifica(read === 1'b0 && write === 1'b0, "t6: NOT nao acessa a memoria");
        passo;

        // ---------------- Desvios ----------------
        desvio(JMP, 1'b1, "JMP          ");

        Z = 1'b1;
        desvio(JZ, 1'b1, "JZ (Z=1)     ");
        Z = 1'b0;
        desvio(JZ, 1'b0, "JZ (Z=0)     ");

        N = 1'b1;
        desvio(JN, 1'b1, "JN (N=1)     ");
        N = 1'b0;
        desvio(JN, 1'b0, "JN (N=0)     ");

        // ---------------- HLT ----------------
        inicia(HLT, "HLT          ");
        busca_e_decodificacao(1'b0);
        // Trava no t6 sem ativar nenhum sinal
        verifica(carga_rem === 1'b0 && carga_rdm === 1'b0 && carga_ac === 1'b0 &&
                 carga_pc === 1'b0 && incrementa_pc === 1'b0 &&
                 read === 1'b0 && write === 1'b0,
                 "t6: HLT nao pode ativar nenhum sinal");
        passo;
        passo;

        $display("\n============================================================");
        if (erros == 0)
            $display(" RESULTADO: todos os testes passaram");
        else
            $display(" RESULTADO: %0d erro(s) encontrado(s)", erros);
        $display("============================================================");

        $finish;
    end

endmodule
