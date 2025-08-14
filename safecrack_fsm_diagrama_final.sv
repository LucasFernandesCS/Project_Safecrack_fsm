/**
 * @module safecrack_fsm_diagrama_final
 * @version 3.3 (Corrigido)
 * @brief Correção final do bug no reset do contador de erros.
 */
module safecrack_fsm_diagrama_final (
    input  logic        clk,
    input  logic        rst,
    input  logic        prog_sw,
    input  logic [3:0]  btn_n,
    output logic        led_green,
    output logic        led_red
);

    // Parâmetros, Estados, Sinais
    localparam int CLK_FREQ = 50_000_000;
    localparam int TIMEOUT_SECONDS = 10;
    localparam int TIMEOUT_MAX_CYCLES = CLK_FREQ * TIMEOUT_SECONDS;

    typedef enum logic [2:0] {
        S_IDLE, S_PROGRAM, S_INPUT, S_CHECK, S_UNLOCKED, S_LOCKED
    } state_t;

    state_t state, next_state;
    logic [3:0] password_reg[0:2];
    logic [3:0] attempt_reg[0:2];
    logic       password_set;
    logic [1:0] password_idx;
    logic [1:0] attempt_idx;
    logic [1:0] error_count;
    logic [31:0] timer_counter;

    // Sincronização e Borda
    logic [3:0] btn_s1, btn_s2, btn_s2_prev;
    logic       prog_sw_s1, prog_sw_s2, prog_sw_s2_prev;
    logic [3:0] btn_fall_edge;
    logic       prog_sw_fall_edge;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin btn_s1 <= 4'hF; btn_s2 <= 4'hF; end
        else begin btn_s1 <= btn_n; btn_s2 <= btn_s1; end
    end
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin prog_sw_s1 <= 1'b0; prog_sw_s2 <= 1'b0; end
        else begin prog_sw_s1 <= prog_sw; prog_sw_s2 <= prog_sw_s1; end
    end
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin btn_s2_prev <= 4'hF; prog_sw_s2_prev <= 1'b0; end
        else begin btn_s2_prev <= btn_s2; prog_sw_s2_prev <= prog_sw_s2; end
    end

    assign btn_fall_edge = btn_s2_prev & ~btn_s2;
    assign prog_sw_fall_edge = prog_sw_s2_prev & ~prog_sw_s2;

    // FSM - Bloco 1: Estado Atual
    always_ff @(posedge clk or posedge rst) begin
        if (rst) state <= S_IDLE;
        else state <= next_state;
    end
	 
	 // FSM - Função Auxiliar
    function automatic bit passwords_match;
        return (password_reg[0] == attempt_reg[0]) &&
               (password_reg[1] == attempt_reg[1]) &&
               (password_reg[2] == attempt_reg[2]);
    endfunction
	 
	 // FSM - Bloco 2: Próximo Estado
    always_comb begin
        next_state = state;
        case (state)
            S_IDLE:
                if (prog_sw_s2 && !password_set) next_state = S_PROGRAM;
                else if (password_set && |btn_fall_edge) next_state = S_INPUT;
            S_PROGRAM:
                if (prog_sw_fall_edge) next_state = S_IDLE;
            S_INPUT:
                if (attempt_idx == 3) next_state = S_CHECK;
            S_CHECK:
                if (passwords_match()) next_state = S_UNLOCKED;
                else if (error_count + 1 >= 3) next_state = S_LOCKED;
                else next_state = S_IDLE;
            S_UNLOCKED:
                if (prog_sw_s2) next_state = S_PROGRAM;
                else if (timer_counter >= TIMEOUT_MAX_CYCLES - 1) next_state = S_IDLE;
            S_LOCKED:
                if (timer_counter >= TIMEOUT_MAX_CYCLES - 1) next_state = S_IDLE;
            default:
                next_state = S_IDLE;
        endcase
    end

    // FSM - Bloco 3: Ações e Saídas
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            password_set <= 1'b0;
            password_idx <= 0;
            attempt_idx  <= 0;
            error_count  <= 0;
            timer_counter <= 0;
        end else begin
            if (state != S_LOCKED && state != S_UNLOCKED) timer_counter <= 0;

            case (state)
                S_IDLE: begin
                    if (next_state == S_INPUT) begin
                        if      (btn_fall_edge[0]) attempt_reg[0] <= 4'd0;
                        else if (btn_fall_edge[1]) attempt_reg[0] <= 4'd1;
                        else if (btn_fall_edge[2]) attempt_reg[0] <= 4'd2;
                        else if (btn_fall_edge[3]) attempt_reg[0] <= 4'd3;
                        attempt_idx <= 1;
                    end else begin
                        attempt_idx <= 0;
                    end
                end

                S_PROGRAM: begin
                    if (!prog_sw_s2_prev) password_idx <= 0;
                    if (|btn_fall_edge && password_idx < 3) begin
                        if      (btn_fall_edge[0]) password_reg[password_idx] <= 4'd0;
                        else if (btn_fall_edge[1]) password_reg[password_idx] <= 4'd1;
                        else if (btn_fall_edge[2]) password_reg[password_idx] <= 4'd2;
                        else if (btn_fall_edge[3]) password_reg[password_idx] <= 4'd3;
                        password_idx <= password_idx + 1;
                    end
                    if (prog_sw_fall_edge && password_idx == 3) password_set <= 1'b1;
                end

                S_INPUT: begin
                    if (|btn_fall_edge && attempt_idx < 3) begin
                        if      (btn_fall_edge[0]) attempt_reg[attempt_idx] <= 4'd0;
                        else if (btn_fall_edge[1]) attempt_reg[attempt_idx] <= 4'd1;
                        else if (btn_fall_edge[2]) attempt_reg[attempt_idx] <= 4'd2;
                        else if (btn_fall_edge[3]) attempt_reg[attempt_idx] <= 4'd3;
                        attempt_idx <= attempt_idx + 1;
                    end
                end

                S_CHECK: begin
                    if (!passwords_match()) error_count <= error_count + 1;
                end

                S_UNLOCKED: begin
                    error_count <= 0;
                    attempt_idx <= 0;
                    timer_counter <= timer_counter + 1;
                end

                S_LOCKED: begin
                    timer_counter <= timer_counter + 1;
                    if (next_state == S_IDLE) begin
                        error_count <= 0;
                    end
                end
            endcase
        end
    end

    // Lógica de Saída
    assign led_green = (state == S_UNLOCKED);
    assign led_red   = (state == S_LOCKED);

endmodule