/**************************************
* Module: CU_tester
* Date:2014-10-30  
* Author: josediaz     
*
* Description: 
***************************************/
module  CU_tester(
);


 integer i;
    reg [7:0] buffer[0:223];
    wire [31:0] IR, PSR, MAR, MDR, PC, nPC, TBR, WIM, TQ,ALU;
    wire [0:0] MFC;
    wire [0:0] IRE, MDRE, TBRE, nPCE, PCE, MARE, nPC_ADD,tQE,tQClr, IRClr, 
    nPC_ADDSEL, TB_ADD, MFA, MOP_SEL, PSRE, BAUX, 
    RFE, RA_SEL, DISP_SEL, AOP_SEL, WIME, ttAUX, ET, ALUE,
    PSR_SUPER, PSR_PREV_SUP, ClrPC, nPCClr;
    wire [31:0] MDR_AUX, MAR_AUX;
    wire [1:0] nPC_SEL, ALU_SEL, CIN_SEL, RC_SEL, MAR_SEL, MDR_SEL, PSR_SEL, TBA_SEL;
    wire [4:0] CWP;
    wire [5:0] OP1;
    wire [24:0] TBA_IN;
    wire [5:0] tQ_IN;
    wire [31:0] WIM_IN;
    
    reg [0:0] Clk, Reset;

DataPathV5 path(IR, PSR, MAR, MDR, PC, nPC, TBR, WIM, TQ, ALU,
                     MFC, IRE, MDRE, TBRE, nPCE, PCE, MARE, nPC_ADD,tQE,tQClr, IRClr, 
                    nPC_ADDSEL, TB_ADD, MFA, MOP_SEL, PSRE, BAUX, 
                    RFE, RA_SEL, DISP_SEL, AOP_SEL, WIME, ttAUX, ET, ALUE,
                    PSR_SUPER, PSR_PREV_SUP, ClrPC, Clk, nPCClr,MDR_AUX,MAR_AUX,
                    nPC_SEL, ALU_SEL, CIN_SEL, RC_SEL, MAR_SEL, MDR_SEL, PSR_SEL, TBA_SEL,
                    CWP,OP1, TBA_IN,
                     tQ_IN, WIM_IN);

CU cu(IRE, TBRE, MDRE, nPCE, PCE, MARE, nPC_ADD, tQE, tQClr, IRClr, nPC_ADDSEL, TB_ADD, MFA, MOP_SEL, PSRE, BAUX, RFE, RA_SEL, DISP_SEL, AOP_SEL, WIME, ttAUX, ET, ALUE, 
PSR_SUPER, PSR_PREV_SUP, ClrPC, nPCClr, MDR_AUX, MAR_AUX, WIM_IN, nPC_SEL, ALU_SEL, CIN_SEL, RC_SEL, MAR_SEL, MDR_SEL, PSR_SEL, TBA_SEL, CWP,
 OP1, TBA_IN, tQ_IN, IR, PSR, MAR, MDR, PC, nPC, TBR, WIM, TQ, ALU, MFC, Clk, Reset);


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

      i = 0;
        $readmemb("fileHH.txt",buffer);
        $display("  Preloading memory from file");
        for(i=0;i<224;i=i+1)begin
            path.ram1.ram[i] = buffer[i[7:0]];
        end
        //path.registerFile.regWin1.block2.reg1.Y = 5;
        //path.registerFile.regWin1.block2.reg2.Y = 0;
          
        #500
        Reset = 0;
        #500
        Reset = 1;  
        #500   
        //==================
        // crap test from here on
      $display("Test Start");
      $display("ALU:\t\tPC:\t\tIR:\t\t\n");
      repeat(100)//760 for first code 
       begin
        #1000
        Clk = 0;
        #1000
        Clk = 1;
        $display("%h\t%h\t%h\t%h\t%h\t", ALU, PC, IR, nPC, MDR,path.registerFile.global.reg1.Y);
       end  
      //$display("ALU:\t\tPC:\t\tIR:\t\t\n"); 
      //$monitor("%h\t%h\t%h\t", ALU, PC, IR); 
 end

endmodule