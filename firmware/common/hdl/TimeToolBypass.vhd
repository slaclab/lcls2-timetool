------------------------------------------------------------------------------
-- File       : TimeToolByPass.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiPkg.all;
use surf.SsiPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;
---------------------------------
---- entity declaration----------
---------------------------------

entity TimeToolByPass is
   generic (
      TPD_G             : time                := 1 ns;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2));
   port (
      -- System Interface
      sysClk               : in  sl;
      sysRst               : in  sl;
      -- DMA Interfaces  (sysClk domain)
      dataInMaster         : in  AxiStreamMasterType;
      dataInSlave          : out AxiStreamSlaveType;
      dataOutMaster        : out AxiStreamMasterType;
      dataOutSlave         : in  AxiStreamSlaveType;

      fromTimeToolMaster   : in  AxiStreamMasterType;
      fromTimeToolSlave    : out AxiStreamSlaveType;

      toTimeToolMaster     : out  AxiStreamMasterType;
      toTimeToolSlave      : in   AxiStreamSlaveType;


      -- AXI-Lite Interface
      axilReadMaster       : in  AxiLiteReadMasterType;
      axilReadSlave        : out AxiLiteReadSlaveType;
      axilWriteMaster      : in  AxiLiteWriteMasterType;
      axilWriteSlave       : out AxiLiteWriteSlaveType);
end TimeToolByPass;


---------------------------------
--------- architecture-----------
---------------------------------

architecture mapping of TimeToolByPass is

   constant INT_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 16, tDestBits => 0);

   ---------------------------------------
   ----record for two process method------
   ---------------------------------------

   type RegType is record
      master               : AxiStreamMasterType;
      slave                : AxiStreamSlaveType;

      toTimeToolMaster     : AxiStreamMasterType;
      toTimeToolSlave      : AxiStreamSlaveType;

      fromTimeToolMaster   : AxiStreamMasterType;
      fromTimeToolSlave    : AxiStreamSlaveType;
  
      byPass               : slv(31 downto 0);
      scratchPad           : slv(31 downto 0);
      axilReadSlave        : AxiLiteReadSlaveType;
      axilWriteSlave       : AxiLiteWriteSlaveType;
   end record RegType;

   ---------------------------------------
   -------record intitial value-----------
   ---------------------------------------

   constant REG_INIT_C : RegType := (
      master                 => AXI_STREAM_MASTER_INIT_C,
      slave                  => AXI_STREAM_SLAVE_INIT_C,

      toTimeToolMaster       => AXI_STREAM_MASTER_INIT_C,
      toTimeToolSlave        => AXI_STREAM_SLAVE_INIT_C,

      fromTimeToolMaster     => AXI_STREAM_MASTER_INIT_C,
      fromTimeToolSlave      => AXI_STREAM_SLAVE_INIT_C,

      byPass                 => (others => '0'),
      scratchPad             => (others => '0'),
      axilReadSlave          => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave         => AXI_LITE_WRITE_SLAVE_INIT_C);

   ---------------------------------------
   -------record intitial value-----------
   ---------------------------------------


   signal r                       : RegType := REG_INIT_C;
   signal rin                     : RegType;

   signal inMaster                : AxiStreamMasterType;
   signal inSlave                 : AxiStreamSlaveType;
   signal outCtrl                 : AxiStreamCtrlType;

   signal fromTimeToolMasterBuf   : AxiStreamMasterType;
   signal fromTimeToolSlaveBuf    : AxiStreamSlaveType;

   signal toTimeToolSlaveBuf      : AxiStreamSlaveType;

begin


   fromTimeToolMasterBuf   <=  fromTimeToolMaster;  
   fromTimeToolSlave       <=  fromTimeToolSlaveBuf;
   toTimeToolSlaveBuf      <=  toTimeToolSlave;

   ---------------------------------
   -- Input FIFO
   ---------------------------------
   U_InFifo : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 500,
         SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => INT_CONFIG_C)
      port map (
         sAxisClk    => sysClk,
         sAxisRst    => sysRst,
         sAxisMaster => dataInMaster,
         sAxisSlave  => dataInSlave,
         mAxisClk    => sysClk,
         mAxisRst    => sysRst,
         mAxisMaster => inMaster,
         mAxisSlave  => inSlave);

   ---------------------------------
   -- Application
   ---------------------------------
   comb : process (axilReadMaster, axilWriteMaster, inMaster, outCtrl, r,
                   sysRst,fromTimeToolMasterBuf, fromTimeToolSlaveBuf,toTimeToolSlaveBuf) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin

      -- Latch the current value
      v := r;

      ------------------------      
      -- AXI-Lite Transactions
      ------------------------      

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister (axilEp, x"0000", 0, v.scratchPad);
      axiSlaveRegister (axilEp, x"0004", 0, v.byPass);

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      ------------------------------
      -- Data Mover
      ------------------------------
      


      if(v.byPass(0) = '1') then
            v.Master                    := inMaster;
            v.slave.tReady              := not outCtrl.pause;

            v.toTimeToolMaster.tValid   := '0';
          
      else
            v.toTimeToolMaster          := inMaster;
            v.Master                    := fromTimeToolMasterBuf;



            v.fromTimeToolSlave.tReady  := not outCtrl.pause;
            v.slave                     := toTimeToolSlaveBuf;
            

      end if;

      -------------
      -- Reset
      -------------
      if (sysRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs 
      axilReadSlave          <= r.axilReadSlave;
      axilWriteSlave         <= r.axilWriteSlave;
      inSlave                <= v.slave;
      fromTimeToolSlaveBuf   <= v.fromTimeToolSlave;

   end process comb;

   seq : process (sysClk) is
   begin
      if (rising_edge(sysClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   ---------------------------------
   -- Output Signals (not FIFO buffered)
   ---------------------------------

   toTimeToolMaster       <= r.toTimeToolMaster;


   ---------------------------------
   -- Output FIFO
   ---------------------------------
   U_OutFifo : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 500,
         SLAVE_AXI_CONFIG_G  => INT_CONFIG_C,
         MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         sAxisClk    => sysClk,
         sAxisRst    => sysRst,
         sAxisMaster => r.Master,
         sAxisCtrl   => outCtrl,
         mAxisClk    => sysClk,
         mAxisRst    => sysRst,
         mAxisMaster => dataOutMaster,
         mAxisSlave  => dataOutSlave);

end mapping;
