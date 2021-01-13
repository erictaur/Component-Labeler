`timescale 1ns/10ps
module CLE ( clk, reset, rom_q, rom_a, sram_a, sram_d, sram_wen, finish);
input         clk;
input         reset;
input  [7:0]  rom_q;
output [6:0]  rom_a;
output [9:0]  sram_a;
output [7:0]  sram_d;
output        sram_wen;
output        finish;

integer i, j, k;

parameter IDLE          = 4'b0000;
parameter LOAD_1        = 4'b0001;
parameter LABEL_1       = 4'b0010;
parameter OVERWRITE_1   = 4'b0011;
parameter PAIR          = 4'b0100;
parameter FILL          = 4'b0101;
parameter LOAD_2        = 4'b0110;
parameter LABEL_2       = 4'b0111;
parameter OVERWRITE_2   = 4'b1000;
parameter FINISH        = 4'b1001;

reg [3:0]  state_c, state_n;
reg [9:0] sram_a_r, sram_a_w;
reg [7:0] sram_d_r, sram_d_w;
reg sram_wen_r, sram_wen_w;
reg finish_r, finish_w;

//For LOAD_1
reg [7:0] rom_address_r, rom_address_w;
reg [1:0] load_col_counter_r, load_col_counter_w;
reg [31:0] BI_r, BI_w;
reg first_row_r, first_row_w;

//For LABEL_1
reg [7:0] LI1_r [31:0];
reg [7:0] LI1_w [31:0];
reg [7:0] LI2_r [31:0];
reg [7:0] LI2_w [31:0];
reg [4:0] col_counter_r, col_counter_w;
reg [4:0] idx; 
reg [7:0] label_count_r, label_count_w;
reg [7:0] vio1_r, vio1_w, vio2_r, vio2_w;
reg conflict;
reg label_fin;

//FOR OVERWRITE_1

//FOR PAIR
reg conflict_fin;
reg [7:0] pair_r [63:0];
reg [7:0] pair_w [63:0];
reg [5:0] pair_counter_r, pair_counter_w;

//FOR FILL
reg fill_fin;

//For LOAD_2

//For LABEL_2

//assign
assign finish = finish_r;
assign sram_a = sram_a_r;
assign sram_d = sram_d_r;
assign sram_wen = sram_wen_r;
assign rom_a    = rom_address_w; // Error Prone


//FSM
always @ (*) begin

    state_n         = state_c;

    case (state_c)
        IDLE: begin
            state_n = LOAD_1;
        end 
        
        LOAD_1: begin
            if (load_col_counter_r == 2'd3) begin
                state_n = LABEL_1;
            end
            else begin
                state_n = state_c;
            end
        end

        LABEL_1: begin
            if (label_fin && !conflict) begin
                state_n = FILL;
            end
            else if(conflict) begin
                state_n = PAIR;
            end
            else if (col_counter_r == 5'd31 && first_row_r) begin
                state_n = LOAD_1;
            end 
            else if(col_counter_r == 5'd31) begin
                state_n = OVERWRITE_1;
            end
            else begin
                state_n = state_c;
            end
        end

        OVERWRITE_1: begin
            //$display("OVERWRITE_1");
            state_n = LOAD_1;
        end

        PAIR: begin
            if (conflict_fin) begin
                state_n = LABEL_1;
            end else begin
                state_n = state_c;
            end
        end 

        FILL: begin
            if (fill_fin) begin
                state_n = LOAD_2;
            end
            else begin
                state_n = state_c;                
            end
        end

        LOAD_2: begin
            if (load_col_counter_r == 2'd3) begin
                state_n = LABEL_2;
            end
            else begin
                state_n = state_c;
            end
        end 

        LABEL_2: begin
            if (label_fin) begin
                state_n = FINISH;
            end
            else if (col_counter_r == 5'd31 && first_row_r) begin
                state_n = LOAD_2;
            end 
            else if(col_counter_r == 5'd31) begin
                state_n = OVERWRITE_2;
            end
            else begin
                state_n = state_c;
            end
        end

        OVERWRITE_2: begin
            state_n = LOAD_2;
        end

        FINISH: begin
            state_n = state_c;
        end

        default: begin
            
        end

    endcase
end

//Do stuff
always @ (*) begin

    sram_a_w                = sram_a_r;
    sram_d_w                = sram_d_r;
    sram_wen_w              = sram_wen_r;
    finish_w                = finish_r;

    //For LOAD_1
    rom_address_w           = rom_address_r;
    load_col_counter_w      = load_col_counter_r;
    BI_w                    = BI_r;
    first_row_w             = first_row_r;
    
    //For LABEL_1
    for(i = 0 ; i < 32 ; i = i + 1)begin                            
                LI1_w[i] = LI1_r[i];                 
                LI2_w[i] = LI2_r[i];
    end
    col_counter_w = col_counter_r;
    idx           = 0;
    label_count_w = label_count_r;
    vio1_w        = vio1_r;
    vio2_w        = vio2_r;
    conflict      = 0;
    label_fin     = 0;

    //FOR OVERWRITE_1

    //FOR PAIR
    for(j = 0 ; j < 64 ; j = j + 1)begin                            
                pair_w[j] = pair_r[j];
    end
    conflict_fin = 0;
    pair_counter_w = pair_counter_r;

    //FOR FILL
    fill_fin = 0;

    //For LOAD_2

    //For LABEL_2

    case (state_c)

        LOAD_1: begin
            case (load_col_counter_r)
                2'b00: BI_w[31:24] = rom_q;
                2'b01: BI_w[23:16] = rom_q;
                2'b10: BI_w[15:8]  = rom_q;
                2'b11: BI_w[7:0]   = rom_q;
            endcase
            rom_address_w = rom_address_r + 1;
            first_row_w = (rom_address_r <= 8'd3) ? 1 : 0;
            load_col_counter_w = (load_col_counter_r == 2'd3) ? 0 : load_col_counter_r + 1;
        end

        LABEL_1: begin
            //First row
            idx = 5'd31 - col_counter_r;
            if (first_row_r) begin
                if (col_counter_r == 5'd0) begin
                    if (BI_r[idx]) begin
                        LI1_w[idx] = label_count_r;
                        label_count_w = label_count_r + 1;
                    end 
                    else begin
                        LI1_w[idx] = 0;
                    end
                    col_counter_w = col_counter_r + 1;
                end
                else if (col_counter_r == 5'd31) begin
                    if (BI_r[idx]) begin
                        if (BI_r[idx + 1]) begin
                            LI1_w[idx] = LI1_r[idx + 1];
                        end
                        else begin
                            LI1_w[idx] = label_count_r;
                            label_count_w = label_count_r + 1;
                        end
                    end 
                    else begin
                        LI1_w[idx] = 0;
                    end
                    col_counter_w = 0;
                end 
                else begin
                    if (BI_r[idx]) begin
                        if (BI_r[idx + 1]) begin
                            LI1_w[idx] = LI1_r[idx + 1];
                        end
                        else begin
                            LI1_w[idx] = label_count_r;
                            label_count_w = label_count_r + 1;
                        end
                    end 
                    else begin
                        LI1_w[idx] = 0;
                        label_count_w = label_count_r;
                    end
                    col_counter_w = col_counter_r + 1;
                end
                if (col_counter_r == 5'd31) begin
                    first_row_w = 0;
                end
                else begin
                    first_row_w = 1;
                end

                sram_a_w = (rom_address_r-8'd4)*8 + col_counter_r;
                sram_d_w = LI1_w[idx];
            end
            else begin
                if (col_counter_r == 5'd0) begin
                    if (BI_r[idx]) begin
                        if (LI1_r[idx-1] != 0) begin
                            LI2_w[idx] = LI1_r[idx-1];
                        end
                        else if (LI1_r[idx] != 0) begin
                            LI2_w[idx] = LI1_r[idx];
                        end
                        else begin
                            LI2_w[idx] = label_count_r;
                            label_count_w = label_count_r + 1;
                        end
                    end
                    else begin
                        LI2_w[idx] = 0;
                    end
                    col_counter_w = col_counter_r + 1;
                end
                else if (col_counter_r == 5'd31) begin
                    if (BI_r[idx]) begin
                        if (LI2_r[idx+1]) begin
                            LI2_w[idx] = LI2_r[idx+1];
                        end 
                        else if (LI1_r[idx]) begin
                            LI2_w[idx] = LI1_r[idx];
                        end
                        else if(LI1_r[idx+1]) begin
                            LI2_w[idx] = LI1_r[idx+1];
                        end
                        else begin
                            LI2_w[idx] = label_count_r;
                            label_count_w = label_count_r + 1;
                        end
                    end
                    else begin
                        LI2_w[idx] = 0;
                    end                    
                    if (rom_address_r == 8'd128) begin
                        label_fin = 1;
                    end
                    else begin
                        label_fin = 0;
                    end
                    col_counter_w = 0;
                end 
                else begin
                    if (BI_r[idx]) begin
                        if (LI1_r[idx-1]) begin // if L3 != 0
                            LI2_w[idx] = LI1_r[idx-1];
                            if (LI2_r[idx+1]) begin // if L5 != 0
                                if (LI1_r[idx-1] != LI2_r[idx+1]) begin
                                    if (LI1_r[idx-1] < LI2_r[idx+1]) begin
                                        vio1_w = LI1_r[idx-1];
                                        vio2_w = LI2_r[idx+1];
                                    end
                                    else begin
                                        vio1_w = LI2_r[idx+1];
                                        vio2_w = LI1_r[idx-1];
                                    end
                                    conflict = 1;
                                end
                                else begin
                                    conflict = 0;
                                end
                            end
                            else if(LI1_r[idx+1]) begin // if L1 != 0
                                if (LI1_r[idx-1] != LI1_r[idx+1]) begin
                                    if (LI1_r[idx-1] < LI1_r[idx+1]) begin
                                        vio1_w = LI1_r[idx-1];
                                        vio2_w = LI1_r[idx+1];
                                    end
                                    else begin
                                        vio1_w = LI1_r[idx+1];
                                        vio2_w = LI1_r[idx-1];
                                    end
                                    conflict = 1;
                                end
                                else begin
                                    conflict = 0;
                                end
                            end
                        end
                        else if(LI2_r[idx+1] != 0) begin
                            LI2_w[idx] = LI2_r[idx+1];
                        end
                        else if(LI1_r[idx] != 0) begin
                            LI2_w[idx] = LI1_r[idx];
                        end
                        else if(LI1_r[idx+1] != 0) begin
                            LI2_w[idx] = LI1_r[idx+1];
                        end
                        else begin
                            LI2_w[idx] = label_count_r;
                            label_count_w = label_count_r + 1;
                        end
                    end
                    else begin
                        LI2_w[idx] = 0;
                    end
                    col_counter_w = col_counter_r + 1;
                end
                sram_a_w = (rom_address_r-8'd4)*8 + col_counter_r;
                sram_d_w = LI2_w[idx];
            end
        end

        OVERWRITE_1: begin
            for(i = 0 ; i < 32 ; i = i + 1)begin
                LI1_w[i] = LI2_r[i];
                LI2_w[i] = 0;
            end
        end

        PAIR: begin

            if (pair_r[vio1_r] == 0 && pair_r[vio2_r] == 0) begin
                pair_w[vio1_r] = vio1_r;
                pair_w[vio2_r] = vio1_r;
                conflict = 0;
                conflict_fin = 1;
            end
            else if (pair_r[vio1_r] != 0 && pair_r[vio2_r] == 0) begin
                pair_w[vio2_r] = pair_r[vio1_r];
                conflict = 0;
                conflict_fin = 1;
            end
            else if (pair_r[vio1_r] == 0 && pair_r[vio2_r] != 0) begin
                pair_w[vio1_r] = pair_r[vio2_r];
                conflict = 0;
                conflict_fin = 1;
            end 
            else if (pair_r[vio1_r] < pair_r[vio2_r]) begin
                if (pair_r[pair_counter_r] == pair_r[vio2_r]) begin
                    pair_w[pair_counter_r] = pair_r[vio1_r];
                end
                if (pair_counter_r == 6'd63) begin
                    conflict = 0;
                    conflict_fin = 1;
                    pair_counter_w = 0;
                end else begin
                    conflict = 1;
                    conflict_fin = 0;
                    pair_counter_w = pair_counter_r + 1;
                end
            end
            else begin
                if (pair_r[pair_counter_r] == pair_r[vio1_r]) begin
                    pair_w[pair_counter_r] = pair_r[vio2_r];
                end
                if (pair_counter_r == 6'd63) begin
                    conflict = 0;
                    conflict_fin = 1;
                    pair_counter_w = 0;
                end else begin
                    conflict = 1;
                    conflict_fin = 0;
                    pair_counter_w = pair_counter_r + 1;
                end
            end

        end 

        FILL: begin
            BI_w = 0;
            rom_address_w = 0;
            label_count_w = 1;
            if (pair_counter_r == 6'd63) begin
                fill_fin = 1;
            end
            else begin
                fill_fin = 0;
            end
            if (pair_r[pair_counter_r] == 0) begin
                pair_w[pair_counter_r] = pair_counter_r;
            end
            pair_counter_w = pair_counter_r + 1;
        end

        LOAD_2: begin
            case (load_col_counter_r)
                2'b00: BI_w[31:24] = rom_q;
                2'b01: BI_w[23:16] = rom_q;
                2'b10: BI_w[15:8]  = rom_q;
                2'b11: BI_w[7:0]   = rom_q;
            endcase
            rom_address_w = rom_address_r + 1;
            first_row_w = (rom_address_r <= 8'd3) ? 1 : 0;
            load_col_counter_w = (load_col_counter_r == 2'd3) ? 0 : load_col_counter_r + 1;
        end 

        LABEL_2: begin
            idx = 5'd31 - col_counter_r;
            if (first_row_r) begin
                if (col_counter_r == 5'd0) begin
                    if (BI_r[idx]) begin
                        LI1_w[idx] = label_count_r;
                        label_count_w = label_count_r + 1;
                    end 
                    else begin
                        LI1_w[idx] = 0;
                    end
                    col_counter_w = col_counter_r + 1;
                end
                else if (col_counter_r == 5'd31) begin
                    if (BI_r[idx]) begin
                        if (BI_r[idx + 1]) begin
                            LI1_w[idx] = LI1_r[idx + 1];
                        end
                        else begin
                            LI1_w[idx] = label_count_r;
                            label_count_w = label_count_r + 1;
                        end
                    end 
                    else begin
                        LI1_w[idx] = 0;
                    end
                    col_counter_w = 0;
                end 
                else begin
                    if (BI_r[idx]) begin
                        if (BI_r[idx + 1]) begin
                            LI1_w[idx] = LI1_r[idx + 1];
                        end
                        else begin
                            LI1_w[idx] = label_count_r;
                            label_count_w = label_count_r + 1;
                        end
                    end 
                    else begin
                        LI1_w[idx] = 0;
                        label_count_w = label_count_r;
                    end
                    col_counter_w = col_counter_r + 1;
                end
                if (col_counter_r == 5'd31) begin
                    first_row_w = 0;
                end
                else begin
                    first_row_w = 1;
                end

                sram_a_w = (rom_address_r-8'd4)*8 + col_counter_r;
                sram_d_w = pair_r[LI1_w[idx]];
                // sram_d_w = LI1_w[idx];
            end
            else begin
                if (col_counter_r == 5'd0) begin
                    if (BI_r[idx]) begin
                        if (LI1_r[idx-1] != 0) begin
                            LI2_w[idx] = LI1_r[idx-1];
                        end
                        else if (LI1_r[idx] != 0) begin
                            LI2_w[idx] = LI1_r[idx];
                        end
                        else begin
                            LI2_w[idx] = label_count_r;
                            label_count_w = label_count_r + 1;
                        end
                    end
                    else begin
                        LI2_w[idx] = 0;
                    end
                    col_counter_w = col_counter_r + 1;
                end
                else if (col_counter_r == 5'd31) begin
                    if (BI_r[idx]) begin
                        if (LI2_r[idx+1]) begin
                            LI2_w[idx] = LI2_r[idx+1];
                        end 
                        else if (LI1_r[idx]) begin
                            LI2_w[idx] = LI1_r[idx];
                        end
                        else if(LI1_r[idx+1]) begin
                            LI2_w[idx] = LI1_r[idx+1];
                        end
                        else begin
                            LI2_w[idx] = label_count_r;
                            label_count_w = label_count_r + 1;
                        end
                    end
                    else begin
                        LI2_w[idx] = 0;
                    end                    
                    if (rom_address_r == 8'd128) begin
                        label_fin = 1;
                    end
                    else begin
                        label_fin = 0;
                    end
                    col_counter_w = 0;
                end 
                else begin
                    if (BI_r[idx]) begin
                        if (LI1_r[idx-1]) begin // if L3 != 0
                            LI2_w[idx] = LI1_r[idx-1];
                        end
                        else if(LI2_r[idx+1] != 0) begin
                            LI2_w[idx] = LI2_r[idx+1];
                        end
                        else if(LI1_r[idx] != 0) begin
                            LI2_w[idx] = LI1_r[idx];
                        end
                        else if(LI1_r[idx+1] != 0) begin
                            LI2_w[idx] = LI1_r[idx+1];
                        end
                        else begin
                            LI2_w[idx] = label_count_r;
                            label_count_w = label_count_r + 1;
                        end
                    end
                    else begin
                        LI2_w[idx] = 0;
                    end
                    col_counter_w = col_counter_r + 1;
                end
                sram_a_w = (rom_address_r-8'd4)*8 + col_counter_r;
                sram_d_w = pair_r[LI2_w[idx]];
                // sram_d_w = LI2_w[idx];
            end
        end

        OVERWRITE_2: begin
            for(i = 0 ; i < 32 ; i = i + 1)begin
                LI1_w[i] = LI2_r[i];
                LI2_w[i] = 0;
            end
        end

        FINISH: begin
            finish_w = 1; 
        end
        
        default: begin
            
        end

    endcase

end

always @ (posedge clk or posedge reset)begin
    if(reset) begin

        state_c <= 0;
        finish_r <= 0;
        sram_a_r <= 0;
        sram_d_r <= 0;
        sram_wen_r <= 0;

        //For LOAD_1
        rom_address_r <= 0;
        load_col_counter_r <= 0;
        BI_r <= 0;
        first_row_r <= 0;

        //For LABEL_1
        for(i = 0 ; i < 32 ; i = i + 1)begin                            
                LI1_r[i] <= 0;                 
                LI2_r[i] <= 0;
        end
        col_counter_r <= 0;
        label_count_r <= 1;
        vio1_r        <= 0;
        vio2_r        <= 0;

        //FOR OVERWRITE_1

        //FOR PAIR
        for(j = 0 ; j < 64 ; j = j + 1)begin                            
                pair_r[j] <= 0;
        end
        pair_counter_r <= 0;

        //FOR FILL

        //For LOAD_2

        //For LABEL_2

    end else begin

        state_c <= state_n;
        finish_r <= finish_w;
        sram_a_r <= sram_a_w;
        sram_d_r <= sram_d_w;
        sram_wen_r <= sram_wen_w;

        //For LOAD_1
        rom_address_r <= rom_address_w;
        load_col_counter_r <= load_col_counter_w;
        BI_r <= BI_w;
        first_row_r <= first_row_w;

        //For LABEL_1
        for(i = 0 ; i < 32 ; i = i + 1)begin                            
                LI1_r[i] <= LI1_w[i];                 
                LI2_r[i] <= LI2_w[i];
        end
        col_counter_r <= col_counter_w;
        label_count_r <= label_count_w;
        vio1_r        <= vio1_w;
        vio2_r        <= vio2_w;

        //FOR OVERWRITE_1

        //FOR PAIR
        for(j = 0 ; j < 64 ; j = j + 1)begin                            
                pair_r[j] <= pair_w[j];
        end
        pair_counter_r <= pair_counter_w;

        //FOR FILL

        //For LOAD_2

        //For LABEL_2

    end
end

endmodule