module safecrackpro_beta_fsm (
    input  logic       clk,
    input  logic       rst,
    input  logic [3:0] btn,        // buttons inputs (BTN[3:0])
    output logic       unlocked    // output: 1 when the safe is unlocked
);

    // one-hot encoding
    typedef enum logic [3:0] { 
        S0 = 4'b0001,  // initial state
        S1 = 4'b0010,  // BTN = 1 right
        S2 = 4'b0100,  // BTN = 2 right
        S3 = 4'b1000  // BTN = 4 right → unlock
    } state_t;

    state_t state, next;

    logic [3:0] passcode[2:0];

    // state transition
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= S0;
            passcode[0] <= 4'b0111;
            passcode[1] <= 4'b1101;
            passcode[2] <= 4'b1101;
        end
        else begin
            state <= next;
        end
    end

    // transition logic
    always_comb begin
        next = S0; // default
        case (state)
            S0:    next = (btn == passcode[0]) ? S1 : S0;
            S1:    next = (btn == passcode[1]) ? S2 : S1;
            S2:    next = (btn == passcode[2]) ? S3 : S2;
            S3:    next = S3;
            default: next = S0;
        endcase
    end

    // output logic
    always_comb begin
        unlocked = (state == S3);
    end

endmodule