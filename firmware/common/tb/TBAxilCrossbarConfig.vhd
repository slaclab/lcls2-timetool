-------------------------------------------------------------------------------
-- File       : TBAxilCrossbarConfig.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-24
-- Last update: 2018-11-08
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-dev'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-dev', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;
use surf.Pgp2bPkg.all;
use surf.SsiPkg.all;

library timetool;
use timetool.TestingPkg.all;


entity TBAxilCrossbarConfig is end TBAxilCrossbarConfig;

architecture testbed of TBAxilCrossbarConfig is
  
   constant TPD_G              : time              := 1 ns;
   constant CLK_PERIOD_G       : time              := 10 ns;

   constant NUM_AXIL_MASTERS_C : natural           := 5;
   constant AXI_BASE_ADDR_G    : slv(31 downto 0)  := x"0051_0000";


   subtype  AXIL_INDEX_RANGE_C is integer range NUM_AXIL_MASTERS_C-1 downto 0;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_INDEX_RANGE_C) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_G, 16, 12);


   signal axilClk       : sl;
   signal axilRst       : sl;

   signal axilWriteMaster             : AxiLiteWriteMasterType :=  AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave              : AxiLiteWriteSlaveType  :=  AXI_LITE_WRITE_SLAVE_INIT_C;
   signal axilReadMaster              : AxiLiteReadMasterType  :=  AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave               : AxiLiteReadSlaveType   :=  AXI_LITE_READ_SLAVE_INIT_C;

  
   signal axilWriteMasters            : AxiLiteWriteMasterArray(AXIL_INDEX_RANGE_C);
   signal axilWriteSlaves             : AxiLiteWriteSlaveArray(AXIL_INDEX_RANGE_C);
   signal axilReadMasters             : AxiLiteReadMasterArray(AXIL_INDEX_RANGE_C);
   signal axilReadSlaves              : AxiLiteReadSlaveArray(AXIL_INDEX_RANGE_C);


begin


   --------------------
   -- Clocks and Resets
   --------------------
   U_axilClk : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_G,
         RST_START_DELAY_G => 1 ns,
         RST_HOLD_TIME_G   => 50 ns)
      port map (
         clkP => axilClk,
         rst  => axilRst); 

     --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);
   
   


end testbed;
