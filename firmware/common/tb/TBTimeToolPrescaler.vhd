-------------------------------------------------------------------------------
-- File       : TimeToolKcu1500.vhd
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

entity TBTimeToolPrescaler is end TBTimeToolPrescaler;

architecture testbed of TBTimeToolPrescaler is

   constant TEST_OUTPUT_FILE_NAME : string := TEST_FILE_PATH & "/output_results.dat";

   constant TPD_G              : time := 1 ns;
   --constant BUILD_INFO_G      : BuildInfoType;

   constant DMA_SIZE_C         : positive := 1;

   constant NUM_AXIL_MASTERS_C : positive := 2;
   constant NUM_MASTERS_G      : positive := 2;
   constant AXI_BASE_ADDR_G    : slv(31 downto 0)    := x"00C0_0000";

   subtype  AXIL_INDEX_RANGE_C is integer range NUM_AXIL_MASTERS_C-1 downto 0;

   constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);  -- 16 byte (128-bit) AXIS interface
   constant DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);
   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_INDEX_RANGE_C) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_G, 16, 12);

   constant CLK_PERIOD_G : time := 10 ns;

   constant SRC_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 4, -- 128 bits
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_FIRST_LAST_C);

   signal userClk156   : sl;

   signal appInMaster  : AxiStreamMasterType;
   signal appInSlave   : AxiStreamSlaveType;
   signal appOutMaster : AxiStreamMasterType;
   signal appOutSlave  : AxiStreamSlaveType;

   signal prescalerToPrescalerMaster   : AxiStreamMasterType;
   signal prescalerToPrescalerSlave    : AxiStreamSlaveType;



   signal axilWriteMasters            : AxiLiteWriteMasterArray(AXIL_INDEX_RANGE_C);
   signal axilWriteSlaves             : AxiLiteWriteSlaveArray(AXIL_INDEX_RANGE_C);
   signal axilReadMasters             : AxiLiteReadMasterArray(AXIL_INDEX_RANGE_C);
   signal axilReadSlaves              : AxiLiteReadSlaveArray(AXIL_INDEX_RANGE_C);

   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_INIT_C;
   signal axilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_INIT_C;

   signal axiClk   : sl;
   signal axiRst   : sl;

   file file_RESULTS : text;

begin

   appOutSlave.tReady <= '1';


   --------------------
   -- Clocks and Resets
   --------------------
   U_axilClk : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_G,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => axiClk,
         rst  => axiRst);


   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axiClk,
         axiClkRst           => axiRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   --------------------
   -- Test data
   --------------------  

      --U_CamOutput : entity timetool.FileToAxiStream
      --   generic map (
      --      TPD_G         => TPD_G,
      --      BYTE_SIZE_C   => 2+1,
      --      AXIS_CONFIG_G => SRC_CONFIG_C)
      --   port map (
      --      axiClk      => axiClk,
      --      axiRst      => axiRst,
      --      mAxisMaster => appInMaster,
      --      mAxisSlave  => appInSlave);

      U_CamOutput : entity timetool.FileToAxiStreamSim
         generic map (
            TPD_G              => TPD_G,
            BYTE_SIZE_C        => 2+1,
            AXIS_CONFIG_G => SRC_CONFIG_C)
         port map (
            axiClk         => axiClk,
            axiRst         => axiRst,
            mAxisMaster    => appInMaster,
            mAxisSlave     => appInSlave);


   --------------------
   -- Modules to be tested
   --------------------  


   U_TimeToolPrescaler : entity timetool.TimeToolPrescaler
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- System Clock and Reset
         sysClk          => axiClk,
         sysRst          => axiRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => appInMaster,
         dataInSlave     => appInSlave,
         dataOutMaster   => prescalerToPrescalerMaster,
         dataOutSlave    => prescalerToPrescalerSlave,
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(0),
         axilReadSlave   => axilReadSlaves(0),
         axilWriteMaster => axilWriteMasters(0),
         axilWriteSlave  => axilWriteSlaves(0));

   U2_TimeToolPrescaler : entity timetool.TimeToolPrescaler
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- System Clock and Reset
         sysClk          => axiClk,
         sysRst          => axiRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => prescalerToPrescalerMaster,
         dataInSlave     => prescalerToPrescalerSlave,
         dataOutMaster   => appOutMaster,
         dataOutSlave    => appOutSlave,
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(1),
         axilReadSlave   => axilReadSlaves(1),
         axilWriteMaster => axilWriteMasters(1),
         axilWriteSlave  => axilWriteSlaves(1));

  ---------------------------------
   -- AXI-Lite Register Transactions
   ---------------------------------
   test : process is
      variable debugData : slv(31 downto 0) := (others => '0');
   begin
      debugData := x"1111_1111";
      ------------------------------------------
      -- Wait for the AXI-Lite reset to complete
      ------------------------------------------
      wait until axiRst = '1';
      wait until axiRst = '0';

      axiLiteBusSimWrite (axiClk, axilWriteMaster, axilWriteSlave, x"00C0_0004", x"2", true);
      axiLiteBusSimWrite (axiClk, axilWriteMaster, axilWriteSlave, x"00C0_1004", x"1", true);

   end process test;

   ---------------------------------
   -- save_file
   ---------------------------------
   save_to_file : process is
      variable to_file              : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      variable v_OLINE              : line; 
      constant c_WIDTH              : natural := 128;
      constant test_data_to_file    : slv(c_WIDTH -1 downto 0) := (others => '0');

   begin

      to_file := appOutMaster;

      file_open(file_RESULTS, TEST_OUTPUT_FILE_NAME, write_mode);

      while true loop

            --write(v_OLINE, appInMaster.tData(c_WIDTH -1 downto 0), right, c_WIDTH);
            write(v_OLINE, appOutMaster.tData(c_WIDTH-1 downto 0), right, c_WIDTH);
            writeline(file_RESULTS, v_OLINE);

            wait for CLK_PERIOD_G;

      end loop;
      
      file_close(file_RESULTS);

   end process save_to_file;

end testbed;
