/**************************************
* Module: DataPathV4
* Date:2014-10-11  
* Author: josediaz     
*
* Description: DataPath with IT - integrated tester
***************************************/
module  DataPathV4();

    integer i;
    reg [31:0] buffer[0:63];
    reg [31:0] IR, PSR, MAR, MDR, PC, nPC, TBR, WIM, MDR_AUX, MAR_AUX, TQ;
    reg [0:0] MFC;
    reg [0:0] IRE, MDRE, TBRE, nPCE, PCE, MARE, nPC_ADD,tQE,tQClr, IRClr, 
    nPC_ADDSEL, TB_ADD, MFA, MOP_SEL, PSRE, BAUX, 
    RFE, RA_SEL, DISP_SEL, AOP_SEL, WIME, ttAUX, ET, ALUE,
    PSR_SUPER, PSR_PREV_SUP, ClrPC, Clk, nPCClr, PSR_SEL, TBA_SEL;
    reg [1:0] nPC_SEL, ALU_SEL, CIN_SEL, RC_SEL, MAR_SEL, MDR_SEL;
    reg [4:0] CWP;
    reg [5:0] OP1;
    reg [24:0] TBA_IN;
    reg [5:0] tQ_IN;
    reg [31:0] WIM_IN;

    //-----------CREATING ALU --------------//
    wire [0:0] N, Z, V, C, Carry;
    wire [31:0] alu_out;
    //output reg [31:0] result, output reg N, Z, V, C, input [31:0] A_in, B_in, input [5:0] opcode, input carry);
    ALU_32bit alu(alu_out,N, Z, V, C, RF_Aout, ALU_MUX_out, AOP_MUX_out[5:0], Carry, ALUE);
    
    //--------CREATING REGISTERS----------//
    
    //buiding IR 
    
    wire [31:0] IR_out;
    register_32bit_le_aclr IR_REG(IR_out,MDR_out,IRE,IRClr,Clk);
    
    //buiding PSR  {{24{ram[address][7]}}, ram[address]};
    //reg [31:0] PSR_in = ; 
    wire [31:0] PSR_out;
    wire [0:0] PSRE_afterGate;
    nor(PSRE_afterGate,ALUE,!PSRE);
    register_32bit_le_aclr PSR_REG(PSR_out,{{8{1'b0}},N, Z, V, C,{12{1'b0}},PSR_MUX_out[7:0]},PSRE_afterGate,1,Clk);
    
    //buiding MAR
    
    wire [31:0] MAR_out;
    register_32bit_le_aclr MAR_REG(MAR_out,MAR_MUX_out,MARE,1,Clk);
    
    //buiding MDR 
    wire [31:0] MDR_out;
    register_32bit_le_aclr MDR_REG(MDR_out,MDR_MUX_out,MDRE,1,Clk);
     
    //buiding nPC
    wire [31:0] nPC_out;
    register_32bit_le_aclr nPC_REG(nPC_out,nPC_MUX_Out,nPCE,nPCClr,Clk);
   
    //buiding PC
    wire [31:0] PC_out;
    register_32bit_le_aclr PC_REG(PC_out,nPC_out,PCE,ClrPC,Clk);
    
    //buiding TBR
    //reg [31:0] TBR_in = {{TBA_IN},{ttAux_out},{4{1'b0}} };
    wire [31:0] TBR_out;
    
    
    wire [0:0] TBRE_afterGate;
    nor(TBRE_afterGate,!TBRE,ttAUX);
    register_32bit_le_aclr TBR_REG(TBR_out,{ TBA_MUX_out[31:7],ttAux_out,{4{1'b0}} },TBRE_afterGate,1,Clk);
    
    //buiding WIM
    wire [31:0] WIM_out;
    register_32bit_le_aclr WIM_REG(WIM_out,WIM_IN,WIME,1,Clk);
    
    //building trap Queue
    wire [31:0] trapQ_out;
    register_32bit_le_aclr trapQueue(trapQ_out,{{26{1'b0}},tQ_IN},tQE,tQClr,Clk);
    
    
    //--------- Special Components* -----//
    
    // branch_Aux(output reg [31:0] out, input [31:0] in_pc, input [29:0] in_disp, input [0:0] BAUX, dispSel);
    //building BranchAux
    wire [31:0] branchAux_out;
    branch_Aux branchAux(branchAux_out,PC_out,IR_out[29:0],BAUX,DISPSEL);
    
    //building tt_Aux
    //tt_Aux(output reg[2:0] out, input wire[5:0] trapQout, input ttAux);
    wire [2:0] ttAux_out;
    tt_Aux ttAux(ttAux_out, trapQ_out[5:0], ttAUX);
    
    //building nPcADD
    //nPC_ADD(output reg [31:0] out, input [31:0] pc, input [0:0] Sel, nPC_ADD);
    wire [31:0] nPC_ADD_out;
    nPC_ADD nPC_ADD_comp(nPC_ADD_out, nPC_out, nPC_ADDSEL, nPC_ADD);
    
    //building TB_ADD
    //TB_ADD(output reg[31:0] out, input wire[31:0] x, input TB_ADD);
    wire [31:0] TB_ADD_out;
    TB_ADD TB_ADD_comp(TB_ADD_out,TBR_out,TB_ADD);
    
    //------------ RAM ---------------//
    //ram_256b(output reg [31:0] DataOut, output reg MFC, input MFA, input [5:0] opcode, input [7:0] address, input [31:0] DataIn);
    wire [31:0] ram_dataOut;
    wire [0:0] MFC_special;
    ram_256b ram1(ram_dataOut, MFC_special, MFA, MOP_MUX_out[5:0], MAR_out[8:0], MDR_out);
    
    //------------ Register file ---------//
    wire [31:0] RF_Aout, RF_Bout;
    //RegisterFile(output reg [31:0] Aout, Bout, input [31:0] Rin, input [1:0] CWP, input [4:0] RA, RB, RC, input RFE, Clk);
    RegisterFile registerFile(RF_Aout, RF_Bout, CIN_MUX_out, CWP[1:0], RA_MUX_out[4:0], IR_out[4:0], RC_MUX_out[4:0], RFE,Clk);
    
    
    //------------ Muxes -------------//
    
    //mux_4x1_32bit(output reg[31:0] Y,input wire[1:0] s, input wire[31:0] I3, I2, I1, I0);
    // buidling nPC_MUX
    wire [31:0] nPC_MUX_Out;
    mux_4x1_32bit nPC_MUX(nPC_MUX_Out, nPC_SEL, alu_out, branchAux_out, TBR_out, nPC_ADD_out); 
    
    //mux_2x1_32bit(output reg[31:0] Y,input wire[0:0] s, input wire[31:0] I1, I0);
    //buidling MOP_MUX
    wire [31:0] MOP_MUX_out;
    mux_2x1_32bit MOP_MUX(MOP_MUX_out,MOP_SEL, {{26{1'b0}},OP1}, {{26{1'b0}},IR_out[24:19]});
    
    //buidling AOP_MUX
    wire [31:0] AOP_MUX_out;
    mux_2x1_32bit AOP_MUX(AOP_MUX_out,AOP_SEL, {{26{1'b0}},OP1}, {{26{1'b0}},IR_out[24:19]});
    
    //buidling ALU_MUX
    //mux_4x1_32bit(output reg[31:0] Y,input wire[1:0] s, input wire[31:0] I3, I2, I1, I0);
    wire [31:0] ALU_MUX_out;
    reg [31:0]ALU;
    mux_4x1_32bit ALU_MUX(ALU_MUX_out, ALU_SEL, {10'h000,IR_out[21:0]}, {25'h0000000,IR_out[6:0]}, {{19{1'b0}},IR_out[12:0]}, RF_Bout);
    
    //building MDR_MUX
    wire [31:0] MDR_MUX_out;
    mux_4x1_32bit MDR_MUX(MDR_MUX_out, MDR_SEL, 32'd0, MDR_AUX,RF_Aout, ram_dataOut);
    
    //building MAR_MUX
    wire [31:0] MAR_MUX_out;
    mux_4x1_32bit MAR_MUX(MAR_MUX_out, MAR_SEL, 32'd0, MAR_AUX, PC_out, alu_out);
    
    //buiding RA_MUX
    wire [31:0] RA_MUX_out;    
    mux_2x1_32bit RA_MUX(RA_MUX_out, RA_SEL, {{27{1'b0}},IR_out[29:25]}, {{27{1'b0}},IR_out[18:14]} );
    
    //building RCMUX
    wire [31:0] RC_MUX_out;
    mux_4x1_32bit RC_MUX(RC_MUX_out, RC_SEL, 15, 17, 18, {{27{1'b0}},IR_out[29:25]});
    
    //buidling CINMUX
    wire [31:0] CIN_MUX_out;
    mux_4x1_32bit CIN_MUX(CIN_MUX_out, CIN_SEL, MDR_out, alu_out, nPC_out, PC_out);
    
    //mux_2x1_32bit(output reg[31:0] Y,input wire[0:0] s, input wire[31:0] I1, I0);
    //buidling TBA_MUX
    wire [31:0] TBA_MUX_out;
    mux_2x1_32bit TBA_MUX(TBA_MUX_out ,TBA_SEL, {TBA_IN,{7{1'b0}}}, {TBR_out[31:7],{7{1'b0}}});
    
    //mux_2x1_32bit(output reg[31:0] Y,input wire[0:0] s, input wire[31:0] I1, I0);
    //buidling PSR_MUX
    wire [31:0] PSR_MUX_out;
    mux_2x1_32bit PSR_MUX(PSR_MUX_out ,PSR_SEL, {{24{1'b0}},PSR_SUPER, PSR_PREV_SUP,ET,CWP}, {{24{1'b0}},PSR_out[7:0]});
    
    
    //-------//
    always @ (*) 
       begin
        MFC = MFC_special;
        IR = IR_out;
        PSR = PSR_out;
        MAR = MAR_out;
        MDR = MDR_out;
        PC = PC_out;
        nPC = nPC_out;
        TBR = TBR_out;
        WIM = WIM_out;
        ALU = alu_out;
        TQ = trapQ_out;
       end

   initial begin               //simulation time
//        ram.ram[0] = 8'h9C;
//        ram.ram[1] = 8'h04;
//        ram.ram[2] = 8'h40;
//        ram.ram[3] = 8'h12;
//        
        i = 0;
//        $readmemh("file.dat",buffer);
//        $display("  Preloading memory from file");
//        MOP_SEL  = 1;
//        MDR_SEL = 2;
//        
//        MDR_AUX = 32'hA2044012;
//        OP1 = 6'h04;
//        MDRE = 1;
//        #100 MDRE  = 0;
//        #30 Clk = 0;
//        #30 Clk =1;
//        #100 Clk <=0;
//        MDRE = 1;
//        #100
//        MFA = 1;
//        #500
//        MFA = 0;

//       i = 0;
//       
//       
//        $readmemh("file2.dat",buffer);
//        $display("  Preloading memory from file");

        i = 0;
        $readmemb("file3.dat",buffer);
        $display("  Preloading memory from file");
        for(i=0;i<128;i=i+1)begin
            ram1.ram[i] = buffer[i[7:0]];
        end
        
        OP1 = 6'h04;
        MOP_SEL  = 1;
        MDR_SEL = 2;
        MAR_SEL = 2;
       
        CWP = 1;
        MAR_AUX = 0;
           MDR_AUX = 15;    
        #100
        MDRE = 0;
        #100
        Clk = 1;
        #100
        Clk = 0;
        MDRE = 1;
        #100
        
        $display("\nStoring MDR in r17");
    RC_SEL = 2'b10;
    #500
    
    CIN_SEL = 3;
    #500
    
    #100
    RFE = 0;
    #500
    Clk = 1;
    #500
    Clk = 0;
    RFE = 1;
        
        
        #50
        MDR_AUX = 17;
        #100
        MDRE = 0;
        #100
        Clk = 1;
        #100
        Clk = 0;
        MDRE = 1;
        #50
         #100
    $display("Storing MDR in r18");
    RC_SEL = 2'b01;
    #500
  
    CIN_SEL = 3;
    #500
    
    #100
    RFE = 0;
    #500
    Clk = 1;
    #500
    Clk = 0;
    RFE = 1;
    #100
  RA_SEL = 0;
    #500
        
        
        
       
//       Clk = 0;
//        #500
//        Clk = 1;
//        #500
//        MAR_SEL <= 2;
//        MAR_AUX <= i;
//        MDR_SEL <= 2;
//        MDR_AUX <= buffer[i[31:0]];
//        MOP_SEL <= 1;
//        OP1 <= 6'b000100;
//        
//        #500
//        Clk = 0;
//        #500
//        Clk = 1;
//        #500
//        MDRE = 0;
//        MARE = 0;
//        
//        #500
//        Clk = 0;
//        #500
//        Clk = 1;
//        #500
//        MDRE = 1;
//        MARE = 1;
//        
//        #500
//        Clk = 0;
//        #500
//        Clk = 1;
//        #500
//        
//        $display("\nMDR_OUT: %h", MDR);
//        $display("MAR_OUT: %h", MAR);
//        //$display("MOP: %b",MOP_MUX_out[5:0]);
//        
//        #500
//        Clk = 0;
//        #500
//        Clk = 1;
//        #500
//        MFA = 1;
//        
//        #500
//        Clk = 0;
//        #500
//        Clk = 1;
//        #500
//        MFA = 0;
        //$display("MDR_OUT: %h", MDR_out);
       
        //==================
        // crap test from here on
    $display("\n========DataPath test========");
    $display("Reset 1");
    #500
    IRE <= 1;
    MDRE <= 1; 
    TBRE <= 1;
    nPCE <= 1;
    PCE <= 1;
    MARE <= 1;
    tQE <= 1;
    nPC_ADD <= 0;
    nPC_ADDSEL <= 1;
    TB_ADD <= 0; 
    MFA <= 0; 
    MOP_SEL <= 1; 
    MAR_SEL <= 1;
    ClrPC <= 1;
    nPCClr <= 1;
    IRClr <= 1;
    nPC_SEL <= 1;
    PSRE <= 1;
    BAUX <= 0;
    RFE <= 1;
    ALUE <= 0;
    tQClr <= 1;
    RA_SEL <= 1;
    MDR_SEL <= 1;
    ALU_SEL <= 1;
    CIN_SEL <= 1;
    RC_SEL <= 1; 
    DISP_SEL <= 1;
    AOP_SEL <= 1;
    WIME <= 1;
    ttAUX <= 1;
    
    #500
    $display("Reset 2");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    //clears en 0
    ClrPC <= 0;
    nPCClr <= 0;
    tQClr <= 0;
    IRClr <= 0;
    
    #500
    $display("Reset 3");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    // putting TBRE = 0
    //Clr <= 1   
    TBRE <= 0;
    nPC_ADDSEL <= 0;
    nPC_SEL <= 0;
    PSRE <= 0;
    RFE <= 0;
    RC_SEL <= 0;
    WIME <= 0;
    ClrPC <= 1;
    nPCClr <= 1;
    tQClr <= 1;
    IRClr <= 1;
    
    #500
    $display("Reset 4");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    TBRE <= 1;
    nPCE  <= 0;
    nPC_ADD <= 1;
    PSRE <= 1;
    RFE <= 1;
    WIME <= 1;
       
    #500
    $display("Reset 5");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    nPCE <= 1; 
    nPC_ADD <= 0;
    
    #500
    $display("RESET DONE");
    $display("\t>>> debug ::: PC: %h - nPC: %h\n", PC, nPC); 
    
    #500
    $display("FETCH 1");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    MARE = 0;
    #1000
    MAR_AUX = 0;
    #1000
    MAR_SEL = 2;
    
    #500
    $display("FETCH 2");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
  
    MARE = 1;
    MOP_SEL = 1;
    #1000
    MDR_SEL = 0;
    #1000
    OP1 = 6'h08;
    
    #500
//    $display("\t>>> debug ::: OP1: %b",OP1 );
//    $display("\t>>> debug ::: MAR: %h",MAR_out );
//    $display("\t>>> debug ::: MOP_MUX_OUT: %h", MOP_MUX_out);
//    $display("\t>>> debug ::: MDR_OUT: %h",MDR_out );
    
    $display("FETCH 3");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    MDRE = 0;
    MFA = 1;
    //MDRE = 1;
        
    #1000
    //$display("\t>>> debug ::: MFC: %b",MFC);
    //$display("\t>>> debug ::: MDR_OUT: %h",MDR_out );
    #1000
    $display("FETCH 4");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    IRE = 0;
    MFA = 0;
    MDRE = 1;
    
    #500
    //$display("\t>>> debug ::: RAM_OUT: %h",MDR_out );
    $display("FETCH 5");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    IRE <= 1;
    
    #500
    $display("FETCH DONE");
    $display("\t>>> debug ::: IR: %h\n", IR);
    
    
    $display("ALop 1");
    
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    CIN_SEL <= 2;
    RA_SEL <= 0;
    RC_SEL <= 0;
    AOP_SEL <= 0;
    ALU_SEL <= 0;
    #500
     $display("ALop 2");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
       
    
    RFE = 0;
    ALUE = 1;
    
    #500
    
     $display("ALop 3");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    RFE = 1;
    ALUE = 0;
    
    #500
    $display("ALop Done");
    //23-20
    $display("\t>>> debug ::: ALU_out: %h", ALU);
    $display("\t>>> debug ::: PSR[23:20]: %b\n", PSR[23:20]);
    
    
    $display("nPC_Update_1");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    PCE <= 0;
    
    #500
    $display("nPC_Update_2");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    PCE <= 1; nPC_ADDSEL <= 0; nPC_SEL <= 0;
    
    #500
    $display("nPC_Update_3");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    nPC_ADD = 1;
    nPCE = 0; 
    
    #500
    $display("nPC_Update_4");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    nPCE = 1; nPC_ADD = 0;
    
    #500
    $display("nPC_Update Done!");
    $display("\t>>> debug ::: PC: %h - nPC: %h\n", PC, nPC);
    
    #500
    Clk = 0;
    RFE = 1;
        
        MDR_SEL <= 2;
        #50
        MDR_AUX = 32'h3c800005;
        #100
        MDRE = 0;
        #100
        Clk = 1;
        #100
        Clk = 0;
        #100
        IRE = 0;
        #100
        Clk = 1;
        #100
        IRE = 1;
    
    #500
    $display("branch instruction wt. cond=false and a=1");
    $display("branch 1");
    #500
    Clk = 0;
    MDRE = 1;
    #500
    Clk = 1;
    #500
    
    PCE <=0;
    
    #500
    $display("branch 2");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    PCE <=1;
    
    #500
    $display("branch F1");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    nPC_ADDSEL <= 1; nPC_SEL <= 0;
    
    #500
    $display("branch F2");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    nPCE <= 0; nPC_ADD <= 1;
    
    #500
    $display("branch F3");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    nPCE <= 1; nPC_ADD <= 0;
    
    #500
    $display("branch false with a=1 done");
    $display("\t>>> debug ::: PC: %h - nPC: %h\n", PC, nPC);
    
     #500
    $display("branch instruction wt. cond=true and disp22=5");
    $display("branch 1");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    PCE <=0;
    
     #500
    $display("branch T1");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    PCE = 1;
    nPC_SEL <= 2; DISP_SEL <= 0;
    
     #500
    $display("branch T2");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    nPCE <= 0; BAUX <= 1;
    
    #500
    $display("branch T3");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    nPCE <= 1; BAUX <= 0;
    
     #500
    $display("branch true is done");
    $display("\t>>> debug ::: PC: %h - nPC: %h\n", PC, nPC);
    
    #500
    Clk = 0;
    RFE = 1;
        PSR_SEL <= 1;
        TBA_SEL <= 1;
        MDR_SEL <= 2;
        #50
        PSR_SUPER <= 0;
        PSR_PREV_SUP <= 1;
        ET <= 1;
        CWP <= 1;
        TBA_IN <= 25'h0000000;
        MDR_AUX = 32'h3c800005;
        tQ_IN = 6'b001000;
        #100
        TBRE = 0;
        MDRE = 0;
        PSRE = 0;
        tQE = 0;
        #100
        Clk = 1;
        #100
        Clk = 0;
        #100
        IRE = 0;
        #100
        Clk = 1;
        #100
        IRE = 1;
    
    #500
    $display("trap instruction wt. cond=true");
    $display("\t>>> debug ::: PSR[7:0]: %b\n", PSR[7:0]);
    $display("trap 1");
    #500
    Clk = 0;
    MDRE = 1;
    TBRE = 1;
    tQE = 1;
    TBA_SEL = 0;
    PSRE = 1;
    #500
    Clk = 1;
    #500
    
    // check cond
    tQ_IN = 6'b001000;
    
    #500
    $display("trap 2");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    tQE <=0;
    
     #500
    $display("trap 3");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    ttAUX = 1;
    tQE <=1;
    
    //$display("\t>>> debug ::: TBR: %b\n", TBR_out);
     #500
    $display("Trap Generated!");
    
     #500
     $display("\t>>> debug ::: trapQ: %b\n", TQ[5:0]);
    $display("trapQ 1");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
    PSR_SEL <= 1;
    PSRE <= 0;
    PSR_SUPER <= 1;
        PSR_PREV_SUP <= 0;
        ET <= 0;
        CWP <= 0;
        RFE <= 0;
        CIN_SEL <= 0;
        RC_SEL <= 2;
        //ttAUX =0;
        
        $display("trapQ 2");
       // $display("\t>>> debug ::: trapQ: %b\n", ttAux_out[2:0]);
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
        PSRE <= 1;
        PSR_SEL <= 0;
        RFE <= 1;
        
        
        
       #500 
       
            $display("trapQ 3");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500
    
        RFE <= 0;
        CIN_SEL <= 1;
        RC_SEL <= 1;
        
        nPC_SEL <= 1;
      #500  
      
            $display("trapQ 4");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500   
     nPCE = 0;
     RFE = 1;
     TBRE = 0;
     #10
     
     
     #500
       $display("trapQ 5");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500   
    TBRE =0;
    nPCE = 1;
    #10
    ttAUX =0;
    
   //PCE = 0;
    
    #500
     $display("trapQ 6");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500   
    //$display("\t>>> debug ::: ttAux: %b\n", ttAux_out[2:0]);
    nPC_ADDSEL = 0;
    nPC_SEL = 1;
    //PCE = 1;
    
    #500
     $display("trapQ 7");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500   
    TBRE = 1;
    nPCE = 0;
    
    //$display("\t>>> debug ::: TBR: %b\n", TBR_out);
   #500 
      $display("trapQ 8");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500   
    
    nPCE = 1;
    PCE = 0;
    
    #500 
      $display("trapQ 9");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500 
    nPC_SEL = 0;
    PCE = 1;
    
      $display("trapQ 9");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500 
    nPC_ADD = 1;
    nPCE = 0;
    PCE = 1;
    
    
     $display("trapQ 10");
    #500
    Clk = 0;
    #500
    Clk = 1;
    #500 
    nPC_ADD = 0;
    nPCE = 1;
    
    
    $display("trap true is done");
    $display("\t>>> debug ::: PC: %h - nPC: %h\n", PC, nPC);
   
    $display("\t>>> debug ::: TBR: %h\n", TBR);
    $display("\t>>> debug ::: PSR[7:0]: %b\n", PSR[7:0]);
    

    
    
     end 

endmodule

