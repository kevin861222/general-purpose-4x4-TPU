
module TPU
#(
    parameter DATA_BITS=8
)
(
input clk,
input rst_n,
input            in_valid,
input [7:0]      K,
input [7:0]      M,
input [7:0]      N,
output           busy,

output           A_wr_en,
output reg [15:0]    A_index,
output [31:0]    A_data_in,
input  [31:0]    A_data_out,

output           B_wr_en,
output reg [15:0]    B_index,
output [31:0]    B_data_in,
input  [31:0]    B_data_out,

output reg       C_wr_en,
output reg [15:0]    C_index,
output reg [127:0]   C_data_in,
input  [127:0]   C_data_out
);
// A/B wr
assign A_wr_en = 0 ;
assign B_wr_en = 0 ;
assign A_data_in = 32'd0 ;
assign B_data_in = 32'd0 ;
// parameter declare
wire zero = 1'b0 ;

reg [DATA_BITS-1:0]     L1      [0:0]  ;  //shift register
reg [DATA_BITS-1:0]     L2      [1:0]  ;
reg [DATA_BITS-1:0]     L3      [2:0]  ;
reg [DATA_BITS-1:0]     T1      [0:0]  ;
reg [DATA_BITS-1:0]     T2      [1:0]  ;
reg [DATA_BITS-1:0]     T3      [2:0]  ;

reg [DATA_BITS-1:0]     PE_L    [15:0] ;
reg [DATA_BITS-1:0]     PE_T    [15:0] ;
reg [DATA_BITS*4-1:0]   PE_ACC  [15:0] ; 
initial begin
    for (i = 0; i<=15 ;i++ ) begin
        PE_L[i] <= 0 ;
        PE_T[i] <= 0 ;
        PE_ACC[i] <= 0 ;
    end
end

//* Implement your design here
// FSM
localparam IDLE = 1'b0 ;
localparam WORK = 1'b1 ;
reg SA_STATE ;
reg next_state ;
initial begin
    SA_STATE = 0 ;
    next_state = 0 ;
end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        SA_STATE <= 0 ;
    end else begin
        SA_STATE <= next_state ;
    end
end
always @(*) begin
    case (SA_STATE)
        IDLE: begin
            next_state = (in_valid) ? (WORK) : (IDLE) ;
        end
        WORK : begin
            next_state = (fourbyfour_num==0)? (IDLE) : (WORK) ;
        end
        default: begin
            next_state = IDLE ;
        end
    endcase
end

// buzy signal
assign busy = SA_STATE ;


// reg and shift
integer i ;
integer j ;
reg [31:0] A_data_out_reg , B_data_out_reg ;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        L1 [0]<= 0 ;
        L2 [0]<= 0 ;
        L2 [1]<= 0 ;
        L3 [0]<= 0 ;
        L3 [1]<= 0 ;
        L3 [2]<= 0 ;
        T1 [0]<= 0 ;
        T2 [0]<= 0 ;
        T2 [1]<= 0 ;
        T3 [0]<= 0 ;
        T3 [1]<= 0 ;
        T3 [2]<= 0 ;
        for (i = 0; i<=15 ;i++ ) begin
            PE_L[i] <= 0 ;
            PE_T[i] <= 0 ;
            PE_ACC[i] <= 0 ;
        end
    end else begin
        if (SA_STATE==WORK) begin

            L3[0] <= B_data_out_reg[7:0] ;
            {L2[0],L3[1]} <= {B_data_out_reg[15:8],L3[0]} ;
            {L1[0],L2[1],L3[2]} <= {B_data_out_reg[23:16],L2[0],L3[1]} ;
            {PE_L[0],PE_L[4],PE_L[8],PE_L[12]} <= {B_data_out_reg[31:24],L1[0],L2[1],L3[2]} ;
            {PE_L[1],PE_L[5],PE_L[9],PE_L[13]} <= {PE_L[0],PE_L[4],PE_L[8],PE_L[12]} ;
            {PE_L[2],PE_L[6],PE_L[10],PE_L[14]} <= {PE_L[1],PE_L[5],PE_L[9],PE_L[13]} ;
            {PE_L[3],PE_L[7],PE_L[11],PE_L[15]} <= {PE_L[2],PE_L[6],PE_L[10],PE_L[14]} ;

            T3[0] <= A_data_out_reg[7:0] ;
            {T2[0],T3[1]} <= {A_data_out_reg[15:8],T3[0]} ;
            {T1[0],T2[1],T3[2]} <= {A_data_out_reg[23:16],T2[0],T3[1]} ;
            {PE_T[0],PE_T[1],PE_T[2],PE_T[3]} <= {A_data_out_reg[31:24],T1[0],T2[1],T3[2]} ;
            {PE_T[4],PE_T[5],PE_T[6],PE_T[7]} <= {PE_T[0],PE_T[1],PE_T[2],PE_T[3]} ;
            {PE_T[8],PE_T[9],PE_T[10],PE_T[11]} <= {PE_T[4],PE_T[5],PE_T[6],PE_T[7]} ;
            {PE_T[12],PE_T[13],PE_T[14],PE_T[15]} <= {PE_T[8],PE_T[9],PE_T[10],PE_T[11]} ;

        end else begin
            L1 [0]<= 0 ;
            L2 [0]<= 0 ;
            L2 [1]<= 0 ;
            L3 [0]<= 0 ;
            L3 [1]<= 0 ;
            L3 [2]<= 0 ;
            T1 [0]<= 0 ;
            T2 [0]<= 0 ;
            T2 [1]<= 0 ;
            T3 [0]<= 0 ;
            T3 [1]<= 0 ;
            T3 [2]<= 0 ;
            for (i = 0; i<=15 ;i++ ) begin
                PE_L[i] <= 0 ;
                PE_T[i] <= 0 ;
            end
        end
    end
end


// ACC and mult / add
integer k ;
integer p ;
integer u ;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        for (k = 0;k<=15 ; k++) begin
            PE_ACC[k] <= 0 ;
        end
    end else begin
        if (SA_STATE==WORK) begin
            case (work_state)
                4'd8: begin
                    for (u = 0; u<=12 ; u=u+4 ) begin
                        PE_ACC[u] <= 32'd0 ;
                    end
                    for (p = 1; p<=13 ; p=p+4 ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                    for (p = 2; p<=14 ; p=p+4 ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                    for (p = 3; p<=15 ; p=p+4 ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                end 
                4'd9: begin
                    for (u = 1; u<=13 ; u=u+4 ) begin
                        PE_ACC[u] <= 32'd0 ;
                    end
                    for (p = 0; p<=12 ; p=p+4 ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                    for (p = 2; p<=14 ; p=p+4 ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                    for (p = 3; p<=15 ; p=p+4 ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                end 
                4'd10: begin
                    for (u = 2; u<=14 ; u=u+4 ) begin
                        PE_ACC[u] <= 32'd0 ;
                    end
                    for (p = 0; p<=12 ; p=p+4 ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                    for (p = 1; p<=13 ; p=p+4 ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                    for (p = 3; p<=15 ; p=p+4 ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                end 
                4'd11: begin
                    for (u = 3; u<=15 ; u=u+4 ) begin
                        PE_ACC[u] <= 32'd0 ;
                    end
                    for (p = 0; p<=12 ; p=p+4 ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                    for (p = 1; p<=13 ; p=p+4 ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                    for (p = 2; p<=14 ; p=p+4 ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                end 
                default: begin
                    for (p = 0; p<=15 ; p++ ) begin
                        PE_ACC[p] <= (PE_L[p]*PE_T[p])+PE_ACC[p] ;
                    end
                end
            endcase
            
        end else begin
        for (k = 0;k<=15 ; k++) begin
            PE_ACC[k] <= 0 ;
        end
        end
    end     
end

// control
reg [3:0] work_state ; 
initial begin 
    work_state = 4'd0 ;
end
reg [7:0] k_count , M_count , N_count ;
reg [7:0] K_reg , M_reg , N_reg , M_real , N_real , M_real_count , N_real_count ;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        work_state <= 4'd0 ;
    end else if (SA_STATE==WORK) begin
        if (work_state==4'd11) begin
            work_state <= (fourbyfour_num==0)?(4'd0):(4'd0);
        end else if (work_state==4'd3) begin
            work_state <= (k_count==K_reg) ? (work_state+1):(4'd3);
        end else begin
            work_state <= work_state+1;
        end
    end else begin
        work_state <= 4'd0 ;
    end
end
// reg [10:0] cycle_count ; 
// reg cycle_rst ;
// always @(posedge clk or negedge rst_n) begin
//     if(~rst_n) begin
//         cycle_count <= 0 ;
//     end else begin
//         if (cycle_rst) begin
//             cycle_count <= 0 ;
//         end else begin
//             cycle_count <= cycle_count+1 ;
//         end
//     end
// end
reg [15:0] fourbyfour_num ;
reg [1:0] Nmod4 , Mmod4 ;
always @(*) begin
    if(in_valid)begin
        Nmod4 = N % 3'd4 ;
        Mmod4 = M % 3'd4 ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        fourbyfour_num <= 0 ;
        K_reg <= 0 ;
        M_reg <= 0 ;
        M_real = 0 ;
        M_real_count <= 0 ;
        N_real_count <= 0 ;
        N_real = 0 ;
        N_reg <= 0 ;
        k_count <= 0 ;
        M_count <= 0 ;
        N_count <= 0 ;
    end else begin
        if (in_valid) begin
            M_real_count <= 0 ;
            N_real_count <= 0 ;
            k_count <= 1 ;
            M_count <= 1 ;
            N_count <= 1 ;
            case (Nmod4)
                0: begin
                    case (Mmod4)
                        0:begin
                            N_reg <= (N/4);
                            M_reg <= (M/4);
                            fourbyfour_num <= ((N/4))*((M/4));
                        end
                        1:begin
                            N_reg <= (N/4);
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4))*((M/4)+1);
                        end
                        2:begin
                            N_reg <= (N/4);
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4))*((M/4)+1);
                        end
                        3:begin
                            N_reg <= (N/4);
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4))*((M/4)+1);
                        end 
                        default: begin
                            N_reg <= (N/4);
                            M_reg <= (M/4);
                            fourbyfour_num <= ((N/4))*((M/4));
                        end
                    endcase
                end
                1:begin
                    case (Mmod4)
                        0:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4);
                            fourbyfour_num <= ((N/4)+1)*((M/4));
                        end
                        1:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4)+1)*((M/4)+1);
                        end
                        2:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4)+1)*((M/4)+1);
                        end
                        3:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4)+1)*((M/4)+1);
                        end 
                        default: begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4)+1)*((M/4));
                        end
                    endcase
                end
                2:begin
                    case (Mmod4)
                        0:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4);
                            fourbyfour_num <= ((N/4)+1)*((M/4));
                        end
                        1:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4)+1)*((M/4)+1);
                        end
                        2:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4)+1)*((M/4)+1);
                        end
                        3:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4)+1)*((M/4)+1);
                        end 
                        default: begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4)+1)*((M/4));
                        end
                    endcase
                end
                2'd3:begin
                    case (Mmod4)
                        0:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4);
                            fourbyfour_num <= ((N/4)+1)*((M/4));
                        end
                        1:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4)+1)*((M/4)+1);
                        end
                        2:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4)+1)*((M/4)+1);
                        end
                        2'd3:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= (((N/4)+1)*((M/4)+1));
                            $display("(((N/4)+1)*((M/4)+1))",(((N/4)+1)*((M/4)+1)));
                        end 
                        default: begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4)+1)*((M/4));
                        end
                    endcase
                end 
                default: begin
                    case (Mmod4)
                        0:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4);
                            fourbyfour_num <= ((N/4))*((M/4));
                        end
                        1:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4))*((M/4)+1);
                        end
                        2:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4))*((M/4)+1);
                        end
                        3:begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4))*((M/4)+1);
                        end 
                        default: begin
                            N_reg <= (N/4)+1;
                            M_reg <= (M/4)+1;
                            fourbyfour_num <= ((N/4))*((M/4));
                        end
                    endcase
                end
            endcase
            // fourbyfour_num <= ((N/4)+1)*((M/4)+1);
            // $display("fourbyfour_num = %d.",fourbyfour_num);
            K_reg <= K ;
            M_real <= M ;
            N_real <= N ;
            // case (K_reg%4)
            //     1:begin
            //         K_reg <= (k/4)+1 ;
            //     end
            //     2:begin
            //         K_reg <= (k/4)+1 ;
            //     end
            //     3:begin
            //         K_reg <= (k/4)+1 ;
            //     end 
            //     default: begin
            //         K_reg <= (k/4) ;
            //     end
            // endcase
            // $monitor("K = %d.",K_reg);
            // $monitor("fourbyfour_num = %d.",fourbyfour_num);
        end 
    end
end

// A B C buffer control 
initial begin
    A_index = 0 ;
    B_index = 0 ;
    C_index = 0 ;
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        A_index <= 0 ;
        B_index <= 0 ;
        C_index <= 0 ;
    end else begin
        if (SA_STATE==WORK) begin
            // $display("work_state = %d.",work_state);
            case (work_state)
                4'd0: begin
                    k_count <= k_count + 1 ;
                    A_index <= A_index + 1 ;
                    B_index <= B_index + 1 ;
                    C_index <= C_index + 0 ;
                end 
                4'd1: begin
                    k_count <= k_count + 1 ;
                    A_index <= A_index + 1 ;
                    B_index <= B_index + 1 ;
                    C_index <= C_index + 0 ;
                end
                4'd2: begin
                    k_count <= k_count + 1 ;
                    A_index <= A_index + 1 ;
                    B_index <= B_index + 1 ;
                    C_index <= C_index + 0 ;
                end
                4'd3: begin
                    // $display("k_count = %d.",k_count);
                    k_count <= k_count + 1 ;
                    A_index <= A_index + 1 ;
                    B_index <= B_index + 1 ;
                    C_index <= C_index + 0 ;
                end
                4'd4: begin
                    k_count <= 11'd1 ;
                    A_index <= A_index + 0 ;
                    B_index <= B_index + 0 ;
                    C_index <= C_index + 0 ;
                end
                4'd5: begin
                    k_count <= 11'd1 ;
                    A_index <= A_index + 0 ;
                    B_index <= B_index + 0 ;
                    C_index <= C_index + 0 ;
                end
                4'd6: begin
                    k_count <= 11'd1 ;
                    A_index <= A_index + 0 ;
                    B_index <= B_index + 0 ;
                    C_index <= C_index + 0 ;
                end
                4'd7: begin
                    k_count <= 11'd1 ;
                    A_index <= A_index + 0 ;
                    B_index <= B_index + 0 ;
                    C_index <= C_index + 0 ;
                end
                4'd8: begin
                    k_count <= 11'd1 ;
                    A_index <= A_index + 0 ;
                    B_index <= B_index + 0 ;
                    C_index <= C_index + 1 ;
                    M_real_count <= M_real_count +1 ;
                    if (M_real_count <= M_real-1) begin
                        C_index <= C_index + 1 ;
                    end else begin
                        C_index <= C_index + 0 ;
                    end
                end
                4'd9: begin
                    k_count <= 11'd1 ;
                    A_index <= A_index + 0 ;
                    B_index <= B_index + 0 ;
                    M_real_count <= M_real_count +1 ;
                    if (M_real_count <= M_real-1) begin
                        C_index <= C_index + 1 ;
                    end else begin
                        C_index <= C_index + 0 ;
                    end
                end
                4'd10: begin
                    k_count <= 11'd1 ;
                    A_index <= A_index + 0 ;
                    B_index <= B_index + 0 ;
                    M_real_count <= M_real_count +1 ;
                    if (M_real_count <= M_real-1) begin
                        C_index <= C_index + 1 ;
                    end else begin
                        C_index <= C_index + 0 ;
                    end
                end
                4'd11: begin
                    k_count <= 11'd1 ;
                    M_real_count <= M_real_count +1 ;
                    A_index <= (M_count==M_reg)? (0):(A_index + 0) ;
                    if (M_count==M_reg)begin
                        M_count <= 1 ;
                        M_real_count <= 0 ;
                        N_count <= N_count + 1 ;
                        B_index <= ((N_count)*K_reg) ;
                    end else begin
                        M_count <= M_count+1 ;
                        B_index <= ((N_count-1)*K_reg) ;
                    end 
                    
                    if (M_real_count <= M_real-1) begin
                        C_index <= C_index + 1 ;
                    end else begin
                        C_index <= C_index + 0 ;
                    end
                    
                    // A_index <= 0 ;
                    // B_index <= 0 ;
                    // C_index <= 0 ;
                    fourbyfour_num <= fourbyfour_num - 1 ;
                end
                default: begin
                    A_index <= A_index + 0 ;
                    B_index <= B_index + 0 ;
                    C_index <= C_index + 0 ;
                end
            endcase
        end else begin
            A_index <= 0 ;
            B_index <= 0 ;
            C_index <= 0 ;
            // C_index <= C_index+0 ;
        end
    end
end

// A_data_out_reg , B_data_out_reg control
always @(*) begin
    if (~rst_n) begin
        A_data_out_reg = 32'd0 ;
        B_data_out_reg = 32'd0 ; 
    end else begin
        if (SA_STATE==WORK) begin
            case (work_state)
                4'd0: begin
                    A_data_out_reg = A_data_out ;
                    B_data_out_reg = B_data_out ;
                    C_data_in      = 32'd0 ;
                    C_wr_en = 0 ;
                end 
                4'd1: begin
                    A_data_out_reg = A_data_out ;
                    B_data_out_reg = B_data_out ;
                    C_data_in      = 32'd0 ;
                    C_wr_en = 0 ;
                end
                4'd2: begin
                    A_data_out_reg = A_data_out ;
                    B_data_out_reg = B_data_out ;
                    C_data_in      = 32'd0 ;
                    C_wr_en = 0 ;
                end
                4'd3: begin
                    A_data_out_reg = A_data_out ;
                    B_data_out_reg = B_data_out ;
                    C_data_in      = 32'd0 ;
                    C_wr_en = 0 ;
                end
                4'd4: begin
                    A_data_out_reg = 32'd0 ;
                    B_data_out_reg = 32'd0 ;
                    C_data_in      = 32'd0 ;
                    C_wr_en = 0 ;
                end
                4'd5: begin
                    A_data_out_reg = 32'd0 ;
                    B_data_out_reg = 32'd0 ;
                    C_data_in      = 32'd0 ;
                    C_wr_en = 0 ;
                end
                4'd6: begin
                    A_data_out_reg = 32'd0 ;
                    B_data_out_reg = 32'd0 ;
                    C_data_in      = 32'd0 ;
                    C_wr_en = 0 ;
                end
                4'd7: begin
                    A_data_out_reg = 32'd0 ;
                    B_data_out_reg = 32'd0 ;
                    C_data_in      = 32'd0 ;
                    C_wr_en = 0 ;
                end
                4'd8: begin
                    A_data_out_reg = 32'd0 ;
                    B_data_out_reg = 32'd0 ;
                    C_data_in      = {PE_ACC[0],PE_ACC[4],PE_ACC[8],PE_ACC[12]} ;
                    // $display("column1 = %h.",C_data_in);
                    if (M_real_count <= M_real-1) begin
                        C_wr_en = 1 ;
                    end else begin
                        C_wr_en = 0 ;
                    end
                end
                4'd9: begin
                    // A_data_out_reg = A_data_out ;
                    // B_data_out_reg = B_data_out ;
                    A_data_out_reg = 32'd0 ;
                    B_data_out_reg = 32'd0 ;
                    C_data_in      = {PE_ACC[1],PE_ACC[5],PE_ACC[9],PE_ACC[13]} ;
                    // $display("column2 = %h.",C_data_in);
                    if (M_real_count <= M_real-1) begin
                        C_wr_en = 1 ;
                    end else begin
                        C_wr_en = 0 ;
                    end
                end
                4'd10: begin
                    // A_data_out_reg = A_data_out ;
                    // B_data_out_reg = B_data_out ;
                    A_data_out_reg = 32'd0 ;
                    B_data_out_reg = 32'd0 ;
                    C_data_in      = {PE_ACC[2],PE_ACC[6],PE_ACC[10],PE_ACC[14]} ;
                    // $display("column3 = %h.",C_data_in);
                    if (M_real_count <= M_real-1) begin
                        C_wr_en = 1 ;
                    end else begin
                        C_wr_en = 0 ;
                    end
                end
                4'd11: begin
                    // A_data_out_reg = A_data_out ;
                    // B_data_out_reg = B_data_out ;
                    A_data_out_reg = 32'd0 ;
                    B_data_out_reg = 32'd0 ;
                    C_data_in      = {PE_ACC[3],PE_ACC[7],PE_ACC[11],PE_ACC[15]} ;
                    // $display("column4 = %h.",C_data_in);
                    if (M_real_count <= M_real-1) begin
                        C_wr_en = 1 ;
                    end else begin
                        C_wr_en = 0 ;
                    end
                end
                default: begin
                    A_data_out_reg = 32'd0 ;
                    B_data_out_reg = 32'd0 ;
                    C_wr_en = 0 ;
                    $display("---- WARING ! data_out_reg case default ----");
                end
            endcase
        end else begin
            A_data_out_reg = 32'd0 ;
            B_data_out_reg = 32'd0 ;
        end
    end
end


// always @(posedge clk) begin
//     if(SA_STATE ==WORK) begin
//         // $display("A_buffer = %h.",A_data_out);
//         // $display("B_buffer = %h.",B_data_out);
//     end
// end

endmodule