library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.user_types.all;

entity ip_sha3v5_v1_0_S00_AXI is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 11
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end ip_sha3v5_v1_0_S00_AXI;

architecture arch_imp of ip_sha3v5_v1_0_S00_AXI is

	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 8;
	------------------------------------------------
	---- Signals for user logic register space example
	signal start		:	std_logic:='0';
    signal S_vector     :   std_logic_vector(1599 downto 0);
    signal S_vector1    :   std_logic_vector(1599 downto 0);
    signal counter_keccak_cycle : std_logic_vector(7 downto 0);
    signal quantity_keccak_cycle: std_logic_vector(31 downto 0);
    signal r:    integer range 0 to 1088;
    signal round_in, round_out  : k_state;
    signal round_constant_signal: std_logic_vector(63 downto 0);
    signal counter_nr_rounds    : unsigned(4 downto 0):=(others=>'0');
    signal A_array      :    k_state;
    signal first        :    std_logic :='0';
    signal last         :    std_logic :='0';
    
    signal theta_in,theta_out,pi_in,pi_out,rho_in,rho_out,chi_in,chi_out,iota_in,iota_out : k_state;
    signal sum_sheet    :   k_plane;
    
    signal signal_temp:std_logic_vector(63 downto 0);
	signal tick        :   std_logic;
	signal tick1       :   std_logic;
	signal cnt         :   unsigned(25 downto 0);
	--------------------------------------------------
	---- Number of Slave Registers 350
	signal slv_reg0	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg1	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg2	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg3	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg4	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg5	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg6	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg7	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg8	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg9	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg10	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg11	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg12	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg13	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg14	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg15	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg16	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg17	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg18	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg19	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg20	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg21	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg22	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg23	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg24	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg25	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg26	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg27	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg28	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg29	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg30	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg31	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg32	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg33	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg34	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg35	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg36	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg37	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg38	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg39	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg40	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg41	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg42	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg43	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg44	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg45	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg46	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg47	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg48	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg49	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg50	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg51	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg52	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg53	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg54	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg55	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg56	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg57	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg58	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg59	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg60	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg61	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg62	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg63	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg64	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg65	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg66	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg67	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg68	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg69	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg70	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg71	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg72	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg73	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg74	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg75	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg76	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg77	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg78	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg79	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg80	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg81	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg82	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg83	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg84	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg85	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg86	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg87	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg88	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg89	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg90	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg91	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg92	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg93	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg94	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg95	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg96	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg97	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg98	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg99	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg100	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg101	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg102	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg103	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg104	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg105	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg106	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg107	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg108	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg109	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg110	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg111	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg112	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg113	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg114	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg115	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg116	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg117	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg118	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg119	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg120	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg121	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg122	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg123	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg124	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg125	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg126	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg127	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg128	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg129	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg130	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg131	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg132	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg133	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg134	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg135	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg136	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg137	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg138	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg139	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg140	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg141	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg142	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg143	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg144	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg145	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg146	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg147	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg148	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg149	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg150	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg151	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg152	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg153	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg154	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg155	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg156	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg157	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg158	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg159	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg160	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg161	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg162	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg163	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg164	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg165	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg166	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg167	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg168	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg169	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg170	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg171	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg172	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg173	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg174	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg175	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg176	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg177	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg178	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg179	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg180	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg181	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg182	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg183	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg184	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg185	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg186	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg187	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg188	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg189	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg190	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg191	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg192	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg193	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg194	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg195	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg196	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg197	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg198	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg199	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg200	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg201	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg202	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg203	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg204	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg205	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg206	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg207	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg208	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg209	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg210	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg211	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg212	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg213	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg214	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg215	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg216	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg217	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg218	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg219	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg220	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg221	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg222	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg223	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg224	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg225	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg226	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg227	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg228	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg229	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg230	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg231	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg232	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg233	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg234	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg235	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg236	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg237	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg238	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg239	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg240	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg241	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg242	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg243	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg244	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg245	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg246	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg247	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg248	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg249	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg250	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg251	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg252	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg253	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg254	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg255	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg256	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg257	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg258	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg259	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg260	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg261	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg262	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg263	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg264	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg265	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg266	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg267	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg268	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg269	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg270	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg271	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg272	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg273	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg274	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg275	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg276	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg277	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg278	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg279	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg280	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg281	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg282	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg283	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg284	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg285	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg286	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg287	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg288	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg289	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg290	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg291	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg292	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg293	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg294	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg295	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg296	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg297	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg298	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg299	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg300	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg301	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg302	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg303	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg304	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg305	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg306	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg307	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg308	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg309	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg310	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg311	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg312	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg313	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg314	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg315	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg316	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg317	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg318	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg319	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg320	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg321	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg322	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg323	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg324	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg325	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg326	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg327	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg328	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg329	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg330	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg331	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg332	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg333	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg334	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg335	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg336	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg337	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg338	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg339	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg340	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg341	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg342	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg343	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg344	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg345	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg346	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg347	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg348	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg349	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal reg_data_out	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	: integer;
	signal aw_en	: std_logic;

begin
	-- I/O Connections assignments

	S_AXI_AWREADY	<= axi_awready;
	S_AXI_WREADY	<= axi_wready;
	S_AXI_BRESP	<= axi_bresp;
	S_AXI_BVALID	<= axi_bvalid;
	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA	<= axi_rdata;
	S_AXI_RRESP	<= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	      aw_en <= '1';
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design 
	        -- expects no outstanding transactions. 
	        axi_awready <= '1';
	        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
	            aw_en <= '1';
	        	axi_awready <= '0';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- S_AXI_AWVALID and S_AXI_WVALID are valid. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- Write Address latching
	        axi_awaddr <= S_AXI_AWADDR;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	-- de-asserted when reset is low. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
	          -- slave is ready to accept write data when 
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design 
	          -- expects no outstanding transactions.           
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process; 

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

	process (S_AXI_ACLK)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      slv_reg0 <= (others => '0');
	      slv_reg1 <= (others => '0');
	      slv_reg2 <= (others => '0');
	      slv_reg3 <= (others => '0');
	      slv_reg4 <= (others => '0');
	      slv_reg5 <= (others => '0');
	      slv_reg6 <= (others => '0');
	      slv_reg7 <= (others => '0');
	      slv_reg8 <= (others => '0');
	      slv_reg9 <= (others => '0');
	      slv_reg10 <= (others => '0');
	      slv_reg11 <= (others => '0');
	      slv_reg12 <= (others => '0');
	      slv_reg13 <= (others => '0');
	      slv_reg14 <= (others => '0');
	      slv_reg15 <= (others => '0');
	      slv_reg16 <= (others => '0');
	      slv_reg17 <= (others => '0');
	      slv_reg18 <= (others => '0');
	      slv_reg19 <= (others => '0');
	      slv_reg20 <= (others => '0');
	      slv_reg21 <= (others => '0');
	      slv_reg22 <= (others => '0');
	      slv_reg23 <= (others => '0');
	      slv_reg24 <= (others => '0');
	      slv_reg25 <= (others => '0');
	      slv_reg26 <= (others => '0');
	      slv_reg27 <= (others => '0');
	      slv_reg28 <= (others => '0');
	      slv_reg29 <= (others => '0');
	      slv_reg30 <= (others => '0');
	      slv_reg31 <= (others => '0');
	      slv_reg32 <= (others => '0');
	      slv_reg33 <= (others => '0');
	      slv_reg34 <= (others => '0');
	      slv_reg35 <= (others => '0');
	      slv_reg36 <= (others => '0');
	      slv_reg37 <= (others => '0');
	      slv_reg38 <= (others => '0');
	      slv_reg39 <= (others => '0');
	      -- slv_reg40 <= (others => '0');
	      -- slv_reg41 <= (others => '0');
	      -- slv_reg42 <= (others => '0');
	      -- slv_reg43 <= (others => '0');
	      -- slv_reg44 <= (others => '0');
	      -- slv_reg45 <= (others => '0');
	      -- slv_reg46 <= (others => '0');
	      -- slv_reg47 <= (others => '0');
	      -- slv_reg48 <= (others => '0');
	      -- slv_reg49 <= (others => '0');
	      -- slv_reg50 <= (others => '0');
	      -- slv_reg51 <= (others => '0');
	      -- slv_reg52 <= (others => '0');
	      -- slv_reg53 <= (others => '0');
	      -- slv_reg54 <= (others => '0');
	      -- slv_reg55 <= (others => '0');
	      -- slv_reg56 <= (others => '0');
	      -- slv_reg57 <= (others => '0');
	      -- slv_reg58 <= (others => '0');
	      -- slv_reg59 <= (others => '0');
	      -- slv_reg60 <= (others => '0');
	      -- slv_reg61 <= (others => '0');
	      -- slv_reg62 <= (others => '0');
	      -- slv_reg63 <= (others => '0');
	      -- slv_reg64 <= (others => '0');
	      -- slv_reg65 <= (others => '0');
	      -- slv_reg66 <= (others => '0');
	      -- slv_reg67 <= (others => '0');
	      -- slv_reg68 <= (others => '0');
	      -- slv_reg69 <= (others => '0');
	      -- slv_reg70 <= (others => '0');
	      -- slv_reg71 <= (others => '0');
	      -- slv_reg72 <= (others => '0');
	      -- slv_reg73 <= (others => '0');
	      -- slv_reg74 <= (others => '0');
	      -- slv_reg75 <= (others => '0');
	      -- slv_reg76 <= (others => '0');
	      -- slv_reg77 <= (others => '0');
	      -- slv_reg78 <= (others => '0');
	      -- slv_reg79 <= (others => '0');
	      -- slv_reg80 <= (others => '0');
	      -- slv_reg81 <= (others => '0');
	      -- slv_reg82 <= (others => '0');
	      -- slv_reg83 <= (others => '0');
	      -- slv_reg84 <= (others => '0');
	      -- slv_reg85 <= (others => '0');
	      -- slv_reg86 <= (others => '0');
	      -- slv_reg87 <= (others => '0');
	      -- slv_reg88 <= (others => '0');
	      -- slv_reg89 <= (others => '0');
	      -- slv_reg90 <= (others => '0');
	      -- slv_reg91 <= (others => '0');
	      -- slv_reg92 <= (others => '0');
	      -- slv_reg93 <= (others => '0');
	      -- slv_reg94 <= (others => '0');
	      -- slv_reg95 <= (others => '0');
	      -- slv_reg96 <= (others => '0');
	      -- slv_reg97 <= (others => '0');
	      -- slv_reg98 <= (others => '0');
	      -- slv_reg99 <= (others => '0');
	      -- slv_reg100 <= (others => '0');
	      -- slv_reg101 <= (others => '0');
	      -- slv_reg102 <= (others => '0');
	      -- slv_reg103 <= (others => '0');
	      -- slv_reg104 <= (others => '0');
	      -- slv_reg105 <= (others => '0');
	      -- slv_reg106 <= (others => '0');
	      -- slv_reg107 <= (others => '0');
	      -- slv_reg108 <= (others => '0');
	      -- slv_reg109 <= (others => '0');
	      -- slv_reg110 <= (others => '0');
	      -- slv_reg111 <= (others => '0');
	      -- slv_reg112 <= (others => '0');
	      -- slv_reg113 <= (others => '0');
	      -- slv_reg114 <= (others => '0');
	      -- slv_reg115 <= (others => '0');
	      -- slv_reg116 <= (others => '0');
	      -- slv_reg117 <= (others => '0');
	      -- slv_reg118 <= (others => '0');
	      -- slv_reg119 <= (others => '0');
	      -- slv_reg120 <= (others => '0');
	      -- slv_reg121 <= (others => '0');
	      -- slv_reg122 <= (others => '0');
	      -- slv_reg123 <= (others => '0');
	      -- slv_reg124 <= (others => '0');
	      -- slv_reg125 <= (others => '0');
	      -- slv_reg126 <= (others => '0');
	      -- slv_reg127 <= (others => '0');
	      -- slv_reg128 <= (others => '0');
	      -- slv_reg129 <= (others => '0');
	      -- slv_reg130 <= (others => '0');
	      -- slv_reg131 <= (others => '0');
	      -- slv_reg132 <= (others => '0');
	      -- slv_reg133 <= (others => '0');
	      -- slv_reg134 <= (others => '0');
	      -- slv_reg135 <= (others => '0');
	      -- slv_reg136 <= (others => '0');
	      -- slv_reg137 <= (others => '0');
	      -- slv_reg138 <= (others => '0');
	      -- slv_reg139 <= (others => '0');
	      -- slv_reg140 <= (others => '0');
	      -- slv_reg141 <= (others => '0');
	      -- slv_reg142 <= (others => '0');
	      -- slv_reg143 <= (others => '0');
	      -- slv_reg144 <= (others => '0');
	      -- slv_reg145 <= (others => '0');
	      -- slv_reg146 <= (others => '0');
	      -- slv_reg147 <= (others => '0');
	      -- slv_reg148 <= (others => '0');
	      -- slv_reg149 <= (others => '0');
	      -- slv_reg150 <= (others => '0');
	      -- slv_reg151 <= (others => '0');
	      -- slv_reg152 <= (others => '0');
	      -- slv_reg153 <= (others => '0');
	      -- slv_reg154 <= (others => '0');
	      -- slv_reg155 <= (others => '0');
	      -- slv_reg156 <= (others => '0');
	      -- slv_reg157 <= (others => '0');
	      -- slv_reg158 <= (others => '0');
	      -- slv_reg159 <= (others => '0');
	      -- slv_reg160 <= (others => '0');
	      -- slv_reg161 <= (others => '0');
	      -- slv_reg162 <= (others => '0');
	      -- slv_reg163 <= (others => '0');
	      -- slv_reg164 <= (others => '0');
	      -- slv_reg165 <= (others => '0');
	      -- slv_reg166 <= (others => '0');
	      -- slv_reg167 <= (others => '0');
	      -- slv_reg168 <= (others => '0');
	      -- slv_reg169 <= (others => '0');
	      -- slv_reg170 <= (others => '0');
	      -- slv_reg171 <= (others => '0');
	      -- slv_reg172 <= (others => '0');
	      -- slv_reg173 <= (others => '0');
	      -- slv_reg174 <= (others => '0');
	      -- slv_reg175 <= (others => '0');
	      -- slv_reg176 <= (others => '0');
	      -- slv_reg177 <= (others => '0');
	      -- slv_reg178 <= (others => '0');
	      -- slv_reg179 <= (others => '0');
	      -- slv_reg180 <= (others => '0');
	      -- slv_reg181 <= (others => '0');
	      -- slv_reg182 <= (others => '0');
	      -- slv_reg183 <= (others => '0');
	      -- slv_reg184 <= (others => '0');
	      -- slv_reg185 <= (others => '0');
	      -- slv_reg186 <= (others => '0');
	      -- slv_reg187 <= (others => '0');
	      -- slv_reg188 <= (others => '0');
	      -- slv_reg189 <= (others => '0');
	      -- slv_reg190 <= (others => '0');
	      -- slv_reg191 <= (others => '0');
	      -- slv_reg192 <= (others => '0');
	      -- slv_reg193 <= (others => '0');
	      -- slv_reg194 <= (others => '0');
	      -- slv_reg195 <= (others => '0');
	      -- slv_reg196 <= (others => '0');
	      -- slv_reg197 <= (others => '0');
	      -- slv_reg198 <= (others => '0');
	      -- slv_reg199 <= (others => '0');
	      -- slv_reg200 <= (others => '0');
	      -- slv_reg201 <= (others => '0');
	      -- slv_reg202 <= (others => '0');
	      -- slv_reg203 <= (others => '0');
	      -- slv_reg204 <= (others => '0');
	      -- slv_reg205 <= (others => '0');
	      -- slv_reg206 <= (others => '0');
	      -- slv_reg207 <= (others => '0');
	      -- slv_reg208 <= (others => '0');
	      -- slv_reg209 <= (others => '0');
	      -- slv_reg210 <= (others => '0');
	      -- slv_reg211 <= (others => '0');
	      -- slv_reg212 <= (others => '0');
	      -- slv_reg213 <= (others => '0');
	      -- slv_reg214 <= (others => '0');
	      -- slv_reg215 <= (others => '0');
	      -- slv_reg216 <= (others => '0');
	      -- slv_reg217 <= (others => '0');
	      -- slv_reg218 <= (others => '0');
	      -- slv_reg219 <= (others => '0');
	      -- slv_reg220 <= (others => '0');
	      -- slv_reg221 <= (others => '0');
	      -- slv_reg222 <= (others => '0');
	      -- slv_reg223 <= (others => '0');
	      -- slv_reg224 <= (others => '0');
	      -- slv_reg225 <= (others => '0');
	      -- slv_reg226 <= (others => '0');
	      -- slv_reg227 <= (others => '0');
	      -- slv_reg228 <= (others => '0');
	      -- slv_reg229 <= (others => '0');
	      -- slv_reg230 <= (others => '0');
	      -- slv_reg231 <= (others => '0');
	      -- slv_reg232 <= (others => '0');
	      -- slv_reg233 <= (others => '0');
	      -- slv_reg234 <= (others => '0');
	      -- slv_reg235 <= (others => '0');
	      -- slv_reg236 <= (others => '0');
	      -- slv_reg237 <= (others => '0');
	      -- slv_reg238 <= (others => '0');
	      -- slv_reg239 <= (others => '0');
	      -- slv_reg240 <= (others => '0');
	      -- slv_reg241 <= (others => '0');
	      -- slv_reg242 <= (others => '0');
	      -- slv_reg243 <= (others => '0');
	      -- slv_reg244 <= (others => '0');
	      -- slv_reg245 <= (others => '0');
	      -- slv_reg246 <= (others => '0');
	      -- slv_reg247 <= (others => '0');
	      -- slv_reg248 <= (others => '0');
	      -- slv_reg249 <= (others => '0');
	      -- slv_reg250 <= (others => '0');
	      -- slv_reg251 <= (others => '0');
	      -- slv_reg252 <= (others => '0');
	      -- slv_reg253 <= (others => '0');
	      -- slv_reg254 <= (others => '0');
	      -- slv_reg255 <= (others => '0');
	      -- slv_reg256 <= (others => '0');
	      -- slv_reg257 <= (others => '0');
	      -- slv_reg258 <= (others => '0');
	      -- slv_reg259 <= (others => '0');
	      -- slv_reg260 <= (others => '0');
	      -- slv_reg261 <= (others => '0');
	      -- slv_reg262 <= (others => '0');
	      -- slv_reg263 <= (others => '0');
	      -- slv_reg264 <= (others => '0');
	      -- slv_reg265 <= (others => '0');
	      -- slv_reg266 <= (others => '0');
	      -- slv_reg267 <= (others => '0');
	      -- slv_reg268 <= (others => '0');
	      -- slv_reg269 <= (others => '0');
	      -- slv_reg270 <= (others => '0');
	      -- slv_reg271 <= (others => '0');
	      -- slv_reg272 <= (others => '0');
	      -- slv_reg273 <= (others => '0');
	      -- slv_reg274 <= (others => '0');
	      -- slv_reg275 <= (others => '0');
	      -- slv_reg276 <= (others => '0');
	      -- slv_reg277 <= (others => '0');
	      -- slv_reg278 <= (others => '0');
	      -- slv_reg279 <= (others => '0');
	      -- slv_reg280 <= (others => '0');
	      -- slv_reg281 <= (others => '0');
	      -- slv_reg282 <= (others => '0');
	      -- slv_reg283 <= (others => '0');
	      -- slv_reg284 <= (others => '0');
	      -- slv_reg285 <= (others => '0');
	      -- slv_reg286 <= (others => '0');
	      -- slv_reg287 <= (others => '0');
	      -- slv_reg288 <= (others => '0');
	      -- slv_reg289 <= (others => '0');
	      -- slv_reg290 <= (others => '0');
	      -- slv_reg291 <= (others => '0');
	      -- slv_reg292 <= (others => '0');
	      -- slv_reg293 <= (others => '0');
	      -- slv_reg294 <= (others => '0');
	      -- slv_reg295 <= (others => '0');
	      -- slv_reg296 <= (others => '0');
	      -- slv_reg297 <= (others => '0');
	      -- slv_reg298 <= (others => '0');
	      -- slv_reg299 <= (others => '0');
	      -- slv_reg300 <= (others => '0');
	      -- slv_reg301 <= (others => '0');
	      -- slv_reg302 <= (others => '0');
	      -- slv_reg303 <= (others => '0');
	      -- slv_reg304 <= (others => '0');
	      -- slv_reg305 <= (others => '0');
	      -- slv_reg306 <= (others => '0');
	      -- slv_reg307 <= (others => '0');
	      -- slv_reg308 <= (others => '0');
	      -- slv_reg309 <= (others => '0');
	      -- slv_reg310 <= (others => '0');
	      -- slv_reg311 <= (others => '0');
	      -- slv_reg312 <= (others => '0');
	      -- slv_reg313 <= (others => '0');
	      -- slv_reg314 <= (others => '0');
	      -- slv_reg315 <= (others => '0');
	      -- slv_reg316 <= (others => '0');
	      -- slv_reg317 <= (others => '0');
	      -- slv_reg318 <= (others => '0');
	      -- slv_reg319 <= (others => '0');
	      -- slv_reg320 <= (others => '0');
	      -- slv_reg321 <= (others => '0');
	      -- slv_reg322 <= (others => '0');
	      -- slv_reg323 <= (others => '0');
	      -- slv_reg324 <= (others => '0');
	      -- slv_reg325 <= (others => '0');
	      -- slv_reg326 <= (others => '0');
	      -- slv_reg327 <= (others => '0');
	      -- slv_reg328 <= (others => '0');
	      -- slv_reg329 <= (others => '0');
	      -- slv_reg330 <= (others => '0');
	      -- slv_reg331 <= (others => '0');
	      -- slv_reg332 <= (others => '0');
	      -- slv_reg333 <= (others => '0');
	      -- slv_reg334 <= (others => '0');
	      -- slv_reg335 <= (others => '0');
	      -- slv_reg336 <= (others => '0');
	      -- slv_reg337 <= (others => '0');
	      -- slv_reg338 <= (others => '0');
	      -- slv_reg339 <= (others => '0');
	      -- slv_reg340 <= (others => '0');
	      -- slv_reg341 <= (others => '0');
	      -- slv_reg342 <= (others => '0');
	      -- slv_reg343 <= (others => '0');
	      -- slv_reg344 <= (others => '0');
	      -- slv_reg345 <= (others => '0');
	      -- slv_reg346 <= (others => '0');
	      -- slv_reg347 <= (others => '0');
	      -- slv_reg348 <= (others => '0');
	      -- slv_reg349 <= (others => '0');
	    else
	      loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	      if (slv_reg_wren = '1') then
	        case loc_addr is
	          when b"000000000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 0
	                slv_reg0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000000001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 1
	                slv_reg1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000000010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 2
	                slv_reg2(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000000011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 3
	                slv_reg3(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000000100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 4
	                slv_reg4(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000000101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 5
	                slv_reg5(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000000110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 6
	                slv_reg6(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000000111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 7
	                slv_reg7(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000001000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 8
	                slv_reg8(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000001001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 9
	                slv_reg9(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000001010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 10
	                slv_reg10(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000001011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 11
	                slv_reg11(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000001100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 12
	                slv_reg12(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000001101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 13
	                slv_reg13(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000001110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 14
	                slv_reg14(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000001111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 15
	                slv_reg15(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000010000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 16
	                slv_reg16(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000010001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 17
	                slv_reg17(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000010010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 18
	                slv_reg18(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000010011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 19
	                slv_reg19(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000010100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 20
	                slv_reg20(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000010101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 21
	                slv_reg21(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000010110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 22
	                slv_reg22(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000010111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 23
	                slv_reg23(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000011000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 24
	                slv_reg24(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000011001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 25
	                slv_reg25(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000011010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 26
	                slv_reg26(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000011011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 27
	                slv_reg27(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000011100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 28
	                slv_reg28(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000011101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 29
	                slv_reg29(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000011110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 30
	                slv_reg30(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000011111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 31
	                slv_reg31(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000100000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 32
	                slv_reg32(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000100001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 33
	                slv_reg33(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000100010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 34
	                slv_reg34(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000100011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 35
	                slv_reg35(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000100100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 36
	                slv_reg36(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000100101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 37
	                slv_reg37(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000100110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 38
	                slv_reg38(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000100111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 39
	                slv_reg39(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          -- when b"000101000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 40
	          --       slv_reg40(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000101001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 41
	          --       slv_reg41(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000101010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 42
	          --       slv_reg42(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000101011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 43
	          --       slv_reg43(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000101100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 44
	          --       slv_reg44(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000101101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 45
	          --       slv_reg45(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000101110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 46
	          --       slv_reg46(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000101111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 47
	          --       slv_reg47(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000110000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 48
	          --       slv_reg48(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000110001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 49
	          --       slv_reg49(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000110010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 50
	          --       slv_reg50(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000110011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 51
	          --       slv_reg51(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000110100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 52
	          --       slv_reg52(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000110101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 53
	          --       slv_reg53(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000110110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 54
	          --       slv_reg54(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000110111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 55
	          --       slv_reg55(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000111000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 56
	          --       slv_reg56(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000111001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 57
	          --       slv_reg57(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000111010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 58
	          --       slv_reg58(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000111011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 59
	          --       slv_reg59(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000111100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 60
	          --       slv_reg60(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000111101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 61
	          --       slv_reg61(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000111110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 62
	          --       slv_reg62(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"000111111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 63
	          --       slv_reg63(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001000000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 64
	          --       slv_reg64(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001000001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 65
	          --       slv_reg65(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001000010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 66
	          --       slv_reg66(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001000011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 67
	          --       slv_reg67(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001000100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 68
	          --       slv_reg68(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001000101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 69
	          --       slv_reg69(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001000110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 70
	          --       slv_reg70(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001000111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 71
	          --       slv_reg71(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001001000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 72
	          --       slv_reg72(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001001001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 73
	          --       slv_reg73(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001001010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 74
	          --       slv_reg74(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001001011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 75
	          --       slv_reg75(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001001100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 76
	          --       slv_reg76(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001001101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 77
	          --       slv_reg77(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001001110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 78
	          --       slv_reg78(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001001111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 79
	          --       slv_reg79(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001010000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 80
	          --       slv_reg80(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001010001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 81
	          --       slv_reg81(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001010010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 82
	          --       slv_reg82(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001010011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 83
	          --       slv_reg83(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001010100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 84
	          --       slv_reg84(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001010101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 85
	          --       slv_reg85(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001010110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 86
	          --       slv_reg86(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001010111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 87
	          --       slv_reg87(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001011000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 88
	          --       slv_reg88(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001011001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 89
	          --       slv_reg89(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001011010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 90
	          --       slv_reg90(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001011011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 91
	          --       slv_reg91(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001011100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 92
	          --       slv_reg92(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001011101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 93
	          --       slv_reg93(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001011110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 94
	          --       slv_reg94(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001011111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 95
	          --       slv_reg95(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001100000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 96
	          --       slv_reg96(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001100001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 97
	          --       slv_reg97(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001100010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 98
	          --       slv_reg98(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001100011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 99
	          --       slv_reg99(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001100100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 100
	          --       slv_reg100(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001100101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 101
	          --       slv_reg101(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001100110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 102
	          --       slv_reg102(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001100111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 103
	          --       slv_reg103(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001101000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 104
	          --       slv_reg104(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001101001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 105
	          --       slv_reg105(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001101010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 106
	          --       slv_reg106(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001101011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 107
	          --       slv_reg107(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001101100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 108
	          --       slv_reg108(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001101101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 109
	          --       slv_reg109(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001101110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 110
	          --       slv_reg110(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001101111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 111
	          --       slv_reg111(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001110000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 112
	          --       slv_reg112(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001110001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 113
	          --       slv_reg113(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001110010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 114
	          --       slv_reg114(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001110011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 115
	          --       slv_reg115(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001110100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 116
	          --       slv_reg116(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001110101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 117
	          --       slv_reg117(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001110110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 118
	          --       slv_reg118(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001110111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 119
	          --       slv_reg119(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001111000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 120
	          --       slv_reg120(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001111001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 121
	          --       slv_reg121(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001111010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 122
	          --       slv_reg122(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001111011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 123
	          --       slv_reg123(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001111100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 124
	          --       slv_reg124(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001111101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 125
	          --       slv_reg125(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001111110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 126
	          --       slv_reg126(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"001111111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 127
	          --       slv_reg127(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010000000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 128
	          --       slv_reg128(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010000001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 129
	          --       slv_reg129(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010000010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 130
	          --       slv_reg130(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010000011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 131
	          --       slv_reg131(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010000100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 132
	          --       slv_reg132(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010000101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 133
	          --       slv_reg133(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010000110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 134
	          --       slv_reg134(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010000111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 135
	          --       slv_reg135(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010001000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 136
	          --       slv_reg136(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010001001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 137
	          --       slv_reg137(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010001010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 138
	          --       slv_reg138(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010001011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 139
	          --       slv_reg139(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010001100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 140
	          --       slv_reg140(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010001101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 141
	          --       slv_reg141(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010001110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 142
	          --       slv_reg142(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010001111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 143
	          --       slv_reg143(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010010000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 144
	          --       slv_reg144(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010010001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 145
	          --       slv_reg145(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010010010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 146
	          --       slv_reg146(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010010011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 147
	          --       slv_reg147(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010010100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 148
	          --       slv_reg148(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010010101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 149
	          --       slv_reg149(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010010110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 150
	          --       slv_reg150(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010010111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 151
	          --       slv_reg151(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010011000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 152
	          --       slv_reg152(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010011001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 153
	          --       slv_reg153(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010011010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 154
	          --       slv_reg154(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010011011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 155
	          --       slv_reg155(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010011100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 156
	          --       slv_reg156(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010011101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 157
	          --       slv_reg157(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010011110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 158
	          --       slv_reg158(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010011111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 159
	          --       slv_reg159(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010100000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 160
	          --       slv_reg160(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010100001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 161
	          --       slv_reg161(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010100010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 162
	          --       slv_reg162(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010100011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 163
	          --       slv_reg163(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010100100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 164
	          --       slv_reg164(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010100101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 165
	          --       slv_reg165(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010100110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 166
	          --       slv_reg166(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010100111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 167
	          --       slv_reg167(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010101000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 168
	          --       slv_reg168(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010101001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 169
	          --       slv_reg169(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010101010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 170
	          --       slv_reg170(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010101011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 171
	          --       slv_reg171(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010101100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 172
	          --       slv_reg172(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010101101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 173
	          --       slv_reg173(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010101110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 174
	          --       slv_reg174(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010101111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 175
	          --       slv_reg175(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010110000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 176
	          --       slv_reg176(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010110001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 177
	          --       slv_reg177(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010110010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 178
	          --       slv_reg178(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010110011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 179
	          --       slv_reg179(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010110100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 180
	          --       slv_reg180(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010110101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 181
	          --       slv_reg181(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010110110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 182
	          --       slv_reg182(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010110111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 183
	          --       slv_reg183(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010111000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 184
	          --       slv_reg184(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010111001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 185
	          --       slv_reg185(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010111010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 186
	          --       slv_reg186(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010111011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 187
	          --       slv_reg187(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010111100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 188
	          --       slv_reg188(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010111101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 189
	          --       slv_reg189(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010111110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 190
	          --       slv_reg190(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"010111111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 191
	          --       slv_reg191(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011000000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 192
	          --       slv_reg192(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011000001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 193
	          --       slv_reg193(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011000010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 194
	          --       slv_reg194(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011000011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 195
	          --       slv_reg195(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011000100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 196
	          --       slv_reg196(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011000101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 197
	          --       slv_reg197(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011000110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 198
	          --       slv_reg198(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011000111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 199
	          --       slv_reg199(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011001000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 200
	          --       slv_reg200(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011001001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 201
	          --       slv_reg201(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011001010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 202
	          --       slv_reg202(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011001011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 203
	          --       slv_reg203(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011001100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 204
	          --       slv_reg204(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011001101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 205
	          --       slv_reg205(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011001110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 206
	          --       slv_reg206(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011001111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 207
	          --       slv_reg207(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011010000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 208
	          --       slv_reg208(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011010001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 209
	          --       slv_reg209(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011010010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 210
	          --       slv_reg210(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011010011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 211
	          --       slv_reg211(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011010100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 212
	          --       slv_reg212(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011010101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 213
	          --       slv_reg213(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011010110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 214
	          --       slv_reg214(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011010111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 215
	          --       slv_reg215(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011011000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 216
	          --       slv_reg216(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011011001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 217
	          --       slv_reg217(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011011010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 218
	          --       slv_reg218(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011011011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 219
	          --       slv_reg219(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011011100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 220
	          --       slv_reg220(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011011101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 221
	          --       slv_reg221(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011011110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 222
	          --       slv_reg222(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011011111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 223
	          --       slv_reg223(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011100000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 224
	          --       slv_reg224(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011100001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 225
	          --       slv_reg225(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011100010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 226
	          --       slv_reg226(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011100011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 227
	          --       slv_reg227(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011100100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 228
	          --       slv_reg228(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011100101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 229
	          --       slv_reg229(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011100110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 230
	          --       slv_reg230(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011100111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 231
	          --       slv_reg231(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011101000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 232
	          --       slv_reg232(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011101001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 233
	          --       slv_reg233(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011101010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 234
	          --       slv_reg234(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011101011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 235
	          --       slv_reg235(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011101100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 236
	          --       slv_reg236(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011101101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 237
	          --       slv_reg237(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011101110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 238
	          --       slv_reg238(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011101111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 239
	          --       slv_reg239(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011110000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 240
	          --       slv_reg240(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011110001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 241
	          --       slv_reg241(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011110010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 242
	          --       slv_reg242(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011110011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 243
	          --       slv_reg243(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011110100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 244
	          --       slv_reg244(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011110101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 245
	          --       slv_reg245(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011110110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 246
	          --       slv_reg246(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011110111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 247
	          --       slv_reg247(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011111000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 248
	          --       slv_reg248(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011111001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 249
	          --       slv_reg249(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011111010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 250
	          --       slv_reg250(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011111011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 251
	          --       slv_reg251(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011111100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 252
	          --       slv_reg252(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011111101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 253
	          --       slv_reg253(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011111110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 254
	          --       slv_reg254(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"011111111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 255
	          --       slv_reg255(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100000000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 256
	          --       slv_reg256(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100000001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 257
	          --       slv_reg257(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100000010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 258
	          --       slv_reg258(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100000011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 259
	          --       slv_reg259(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100000100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 260
	          --       slv_reg260(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100000101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 261
	          --       slv_reg261(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100000110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 262
	          --       slv_reg262(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100000111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 263
	          --       slv_reg263(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100001000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 264
	          --       slv_reg264(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100001001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 265
	          --       slv_reg265(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100001010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 266
	          --       slv_reg266(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100001011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 267
	          --       slv_reg267(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100001100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 268
	          --       slv_reg268(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100001101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 269
	          --       slv_reg269(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100001110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 270
	          --       slv_reg270(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100001111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 271
	          --       slv_reg271(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100010000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 272
	          --       slv_reg272(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100010001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 273
	          --       slv_reg273(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100010010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 274
	          --       slv_reg274(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100010011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 275
	          --       slv_reg275(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100010100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 276
	          --       slv_reg276(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100010101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 277
	          --       slv_reg277(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100010110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 278
	          --       slv_reg278(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100010111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 279
	          --       slv_reg279(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100011000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 280
	          --       slv_reg280(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100011001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 281
	          --       slv_reg281(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100011010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 282
	          --       slv_reg282(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100011011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 283
	          --       slv_reg283(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100011100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 284
	          --       slv_reg284(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100011101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 285
	          --       slv_reg285(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100011110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 286
	          --       slv_reg286(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100011111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 287
	          --       slv_reg287(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100100000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 288
	          --       slv_reg288(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100100001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 289
	          --       slv_reg289(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100100010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 290
	          --       slv_reg290(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100100011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 291
	          --       slv_reg291(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100100100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 292
	          --       slv_reg292(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100100101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 293
	          --       slv_reg293(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100100110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 294
	          --       slv_reg294(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100100111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 295
	          --       slv_reg295(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100101000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 296
	          --       slv_reg296(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100101001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 297
	          --       slv_reg297(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100101010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 298
	          --       slv_reg298(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100101011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 299
	          --       slv_reg299(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100101100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 300
	          --       slv_reg300(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100101101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 301
	          --       slv_reg301(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100101110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 302
	          --       slv_reg302(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100101111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 303
	          --       slv_reg303(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100110000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 304
	          --       slv_reg304(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100110001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 305
	          --       slv_reg305(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100110010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 306
	          --       slv_reg306(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100110011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 307
	          --       slv_reg307(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100110100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 308
	          --       slv_reg308(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100110101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 309
	          --       slv_reg309(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100110110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 310
	          --       slv_reg310(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100110111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 311
	          --       slv_reg311(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100111000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 312
	          --       slv_reg312(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100111001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 313
	          --       slv_reg313(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100111010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 314
	          --       slv_reg314(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100111011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 315
	          --       slv_reg315(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100111100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 316
	          --       slv_reg316(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100111101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 317
	          --       slv_reg317(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100111110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 318
	          --       slv_reg318(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"100111111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 319
	          --       slv_reg319(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101000000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 320
	          --       slv_reg320(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101000001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 321
	          --       slv_reg321(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101000010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 322
	          --       slv_reg322(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101000011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 323
	          --       slv_reg323(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101000100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 324
	          --       slv_reg324(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101000101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 325
	          --       slv_reg325(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101000110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 326
	          --       slv_reg326(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101000111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 327
	          --       slv_reg327(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101001000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 328
	          --       slv_reg328(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101001001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 329
	          --       slv_reg329(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101001010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 330
	          --       slv_reg330(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101001011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 331
	          --       slv_reg331(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101001100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 332
	          --       slv_reg332(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101001101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 333
	          --       slv_reg333(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101001110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 334
	          --       slv_reg334(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101001111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 335
	          --       slv_reg335(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101010000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 336
	          --       slv_reg336(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101010001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 337
	          --       slv_reg337(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101010010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 338
	          --       slv_reg338(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101010011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 339
	          --       slv_reg339(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101010100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 340
	          --       slv_reg340(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101010101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 341
	          --       slv_reg341(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101010110" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 342
	          --       slv_reg342(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101010111" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 343
	          --       slv_reg343(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101011000" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 344
	          --       slv_reg344(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101011001" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 345
	          --       slv_reg345(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101011010" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 346
	          --       slv_reg346(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101011011" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 347
	          --       slv_reg347(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101011100" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 348
	          --       slv_reg348(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          -- when b"101011101" =>
	          --   for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	          --     if ( S_AXI_WSTRB(byte_index) = '1' ) then
	          --       -- Respective byte enables are asserted as per write strobes                   
	          --       -- slave registor 349
	          --       slv_reg349(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	          --     end if;
	          --   end loop;
	          when others =>
	            slv_reg0 <= slv_reg0;
	            slv_reg1 <= slv_reg1;
	            slv_reg2 <= slv_reg2;
	            slv_reg3 <= slv_reg3;
	            slv_reg4 <= slv_reg4;
	            slv_reg5 <= slv_reg5;
	            slv_reg6 <= slv_reg6;
	            slv_reg7 <= slv_reg7;
	            slv_reg8 <= slv_reg8;
	            slv_reg9 <= slv_reg9;
	            slv_reg10 <= slv_reg10;
	            slv_reg11 <= slv_reg11;
	            slv_reg12 <= slv_reg12;
	            slv_reg13 <= slv_reg13;
	            slv_reg14 <= slv_reg14;
	            slv_reg15 <= slv_reg15;
	            slv_reg16 <= slv_reg16;
	            slv_reg17 <= slv_reg17;
	            slv_reg18 <= slv_reg18;
	            slv_reg19 <= slv_reg19;
	            slv_reg20 <= slv_reg20;
	            slv_reg21 <= slv_reg21;
	            slv_reg22 <= slv_reg22;
	            slv_reg23 <= slv_reg23;
	            slv_reg24 <= slv_reg24;
	            slv_reg25 <= slv_reg25;
	            slv_reg26 <= slv_reg26;
	            slv_reg27 <= slv_reg27;
	            slv_reg28 <= slv_reg28;
	            slv_reg29 <= slv_reg29;
	            slv_reg30 <= slv_reg30;
	            slv_reg31 <= slv_reg31;
	            slv_reg32 <= slv_reg32;
	            slv_reg33 <= slv_reg33;
	            slv_reg34 <= slv_reg34;
	            slv_reg35 <= slv_reg35;
	            slv_reg36 <= slv_reg36;
	            slv_reg37 <= slv_reg37;
	            slv_reg38 <= slv_reg38;
	            slv_reg39 <= slv_reg39;
	            -- slv_reg40 <= slv_reg40;
	            -- slv_reg41 <= slv_reg41;
	            -- slv_reg42 <= slv_reg42;
	            -- slv_reg43 <= slv_reg43;
	            -- slv_reg44 <= slv_reg44;
	            -- slv_reg45 <= slv_reg45;
	            -- slv_reg46 <= slv_reg46;
	            -- slv_reg47 <= slv_reg47;
	            -- slv_reg48 <= slv_reg48;
	            -- slv_reg49 <= slv_reg49;
	            -- slv_reg50 <= slv_reg50;
	            -- slv_reg51 <= slv_reg51;
	            -- slv_reg52 <= slv_reg52;
	            -- slv_reg53 <= slv_reg53;
	            -- slv_reg54 <= slv_reg54;
	            -- slv_reg55 <= slv_reg55;
	            -- slv_reg56 <= slv_reg56;
	            -- slv_reg57 <= slv_reg57;
	            -- slv_reg58 <= slv_reg58;
	            -- slv_reg59 <= slv_reg59;
	            -- slv_reg60 <= slv_reg60;
	            -- slv_reg61 <= slv_reg61;
	            -- slv_reg62 <= slv_reg62;
	            -- slv_reg63 <= slv_reg63;
	            -- slv_reg64 <= slv_reg64;
	            -- slv_reg65 <= slv_reg65;
	            -- slv_reg66 <= slv_reg66;
	            -- slv_reg67 <= slv_reg67;
	            -- slv_reg68 <= slv_reg68;
	            -- slv_reg69 <= slv_reg69;
	            -- slv_reg70 <= slv_reg70;
	            -- slv_reg71 <= slv_reg71;
	            -- slv_reg72 <= slv_reg72;
	            -- slv_reg73 <= slv_reg73;
	            -- slv_reg74 <= slv_reg74;
	            -- slv_reg75 <= slv_reg75;
	            -- slv_reg76 <= slv_reg76;
	            -- slv_reg77 <= slv_reg77;
	            -- slv_reg78 <= slv_reg78;
	            -- slv_reg79 <= slv_reg79;
	            -- slv_reg80 <= slv_reg80;
	            -- slv_reg81 <= slv_reg81;
	            -- slv_reg82 <= slv_reg82;
	            -- slv_reg83 <= slv_reg83;
	            -- slv_reg84 <= slv_reg84;
	            -- slv_reg85 <= slv_reg85;
	            -- slv_reg86 <= slv_reg86;
	            -- slv_reg87 <= slv_reg87;
	            -- slv_reg88 <= slv_reg88;
	            -- slv_reg89 <= slv_reg89;
	            -- slv_reg90 <= slv_reg90;
	            -- slv_reg91 <= slv_reg91;
	            -- slv_reg92 <= slv_reg92;
	            -- slv_reg93 <= slv_reg93;
	            -- slv_reg94 <= slv_reg94;
	            -- slv_reg95 <= slv_reg95;
	            -- slv_reg96 <= slv_reg96;
	            -- slv_reg97 <= slv_reg97;
	            -- slv_reg98 <= slv_reg98;
	            -- slv_reg99 <= slv_reg99;
	            -- slv_reg100 <= slv_reg100;
	            -- slv_reg101 <= slv_reg101;
	            -- slv_reg102 <= slv_reg102;
	            -- slv_reg103 <= slv_reg103;
	            -- slv_reg104 <= slv_reg104;
	            -- slv_reg105 <= slv_reg105;
	            -- slv_reg106 <= slv_reg106;
	            -- slv_reg107 <= slv_reg107;
	            -- slv_reg108 <= slv_reg108;
	            -- slv_reg109 <= slv_reg109;
	            -- slv_reg110 <= slv_reg110;
	            -- slv_reg111 <= slv_reg111;
	            -- slv_reg112 <= slv_reg112;
	            -- slv_reg113 <= slv_reg113;
	            -- slv_reg114 <= slv_reg114;
	            -- slv_reg115 <= slv_reg115;
	            -- slv_reg116 <= slv_reg116;
	            -- slv_reg117 <= slv_reg117;
	            -- slv_reg118 <= slv_reg118;
	            -- slv_reg119 <= slv_reg119;
	            -- slv_reg120 <= slv_reg120;
	            -- slv_reg121 <= slv_reg121;
	            -- slv_reg122 <= slv_reg122;
	            -- slv_reg123 <= slv_reg123;
	            -- slv_reg124 <= slv_reg124;
	            -- slv_reg125 <= slv_reg125;
	            -- slv_reg126 <= slv_reg126;
	            -- slv_reg127 <= slv_reg127;
	            -- slv_reg128 <= slv_reg128;
	            -- slv_reg129 <= slv_reg129;
	            -- slv_reg130 <= slv_reg130;
	            -- slv_reg131 <= slv_reg131;
	            -- slv_reg132 <= slv_reg132;
	            -- slv_reg133 <= slv_reg133;
	            -- slv_reg134 <= slv_reg134;
	            -- slv_reg135 <= slv_reg135;
	            -- slv_reg136 <= slv_reg136;
	            -- slv_reg137 <= slv_reg137;
	            -- slv_reg138 <= slv_reg138;
	            -- slv_reg139 <= slv_reg139;
	            -- slv_reg140 <= slv_reg140;
	            -- slv_reg141 <= slv_reg141;
	            -- slv_reg142 <= slv_reg142;
	            -- slv_reg143 <= slv_reg143;
	            -- slv_reg144 <= slv_reg144;
	            -- slv_reg145 <= slv_reg145;
	            -- slv_reg146 <= slv_reg146;
	            -- slv_reg147 <= slv_reg147;
	            -- slv_reg148 <= slv_reg148;
	            -- slv_reg149 <= slv_reg149;
	            -- slv_reg150 <= slv_reg150;
	            -- slv_reg151 <= slv_reg151;
	            -- slv_reg152 <= slv_reg152;
	            -- slv_reg153 <= slv_reg153;
	            -- slv_reg154 <= slv_reg154;
	            -- slv_reg155 <= slv_reg155;
	            -- slv_reg156 <= slv_reg156;
	            -- slv_reg157 <= slv_reg157;
	            -- slv_reg158 <= slv_reg158;
	            -- slv_reg159 <= slv_reg159;
	            -- slv_reg160 <= slv_reg160;
	            -- slv_reg161 <= slv_reg161;
	            -- slv_reg162 <= slv_reg162;
	            -- slv_reg163 <= slv_reg163;
	            -- slv_reg164 <= slv_reg164;
	            -- slv_reg165 <= slv_reg165;
	            -- slv_reg166 <= slv_reg166;
	            -- slv_reg167 <= slv_reg167;
	            -- slv_reg168 <= slv_reg168;
	            -- slv_reg169 <= slv_reg169;
	            -- slv_reg170 <= slv_reg170;
	            -- slv_reg171 <= slv_reg171;
	            -- slv_reg172 <= slv_reg172;
	            -- slv_reg173 <= slv_reg173;
	            -- slv_reg174 <= slv_reg174;
	            -- slv_reg175 <= slv_reg175;
	            -- slv_reg176 <= slv_reg176;
	            -- slv_reg177 <= slv_reg177;
	            -- slv_reg178 <= slv_reg178;
	            -- slv_reg179 <= slv_reg179;
	            -- slv_reg180 <= slv_reg180;
	            -- slv_reg181 <= slv_reg181;
	            -- slv_reg182 <= slv_reg182;
	            -- slv_reg183 <= slv_reg183;
	            -- slv_reg184 <= slv_reg184;
	            -- slv_reg185 <= slv_reg185;
	            -- slv_reg186 <= slv_reg186;
	            -- slv_reg187 <= slv_reg187;
	            -- slv_reg188 <= slv_reg188;
	            -- slv_reg189 <= slv_reg189;
	            -- slv_reg190 <= slv_reg190;
	            -- slv_reg191 <= slv_reg191;
	            -- slv_reg192 <= slv_reg192;
	            -- slv_reg193 <= slv_reg193;
	            -- slv_reg194 <= slv_reg194;
	            -- slv_reg195 <= slv_reg195;
	            -- slv_reg196 <= slv_reg196;
	            -- slv_reg197 <= slv_reg197;
	            -- slv_reg198 <= slv_reg198;
	            -- slv_reg199 <= slv_reg199;
	            -- slv_reg200 <= slv_reg200;
	            -- slv_reg201 <= slv_reg201;
	            -- slv_reg202 <= slv_reg202;
	            -- slv_reg203 <= slv_reg203;
	            -- slv_reg204 <= slv_reg204;
	            -- slv_reg205 <= slv_reg205;
	            -- slv_reg206 <= slv_reg206;
	            -- slv_reg207 <= slv_reg207;
	            -- slv_reg208 <= slv_reg208;
	            -- slv_reg209 <= slv_reg209;
	            -- slv_reg210 <= slv_reg210;
	            -- slv_reg211 <= slv_reg211;
	            -- slv_reg212 <= slv_reg212;
	            -- slv_reg213 <= slv_reg213;
	            -- slv_reg214 <= slv_reg214;
	            -- slv_reg215 <= slv_reg215;
	            -- slv_reg216 <= slv_reg216;
	            -- slv_reg217 <= slv_reg217;
	            -- slv_reg218 <= slv_reg218;
	            -- slv_reg219 <= slv_reg219;
	            -- slv_reg220 <= slv_reg220;
	            -- slv_reg221 <= slv_reg221;
	            -- slv_reg222 <= slv_reg222;
	            -- slv_reg223 <= slv_reg223;
	            -- slv_reg224 <= slv_reg224;
	            -- slv_reg225 <= slv_reg225;
	            -- slv_reg226 <= slv_reg226;
	            -- slv_reg227 <= slv_reg227;
	            -- slv_reg228 <= slv_reg228;
	            -- slv_reg229 <= slv_reg229;
	            -- slv_reg230 <= slv_reg230;
	            -- slv_reg231 <= slv_reg231;
	            -- slv_reg232 <= slv_reg232;
	            -- slv_reg233 <= slv_reg233;
	            -- slv_reg234 <= slv_reg234;
	            -- slv_reg235 <= slv_reg235;
	            -- slv_reg236 <= slv_reg236;
	            -- slv_reg237 <= slv_reg237;
	            -- slv_reg238 <= slv_reg238;
	            -- slv_reg239 <= slv_reg239;
	            -- slv_reg240 <= slv_reg240;
	            -- slv_reg241 <= slv_reg241;
	            -- slv_reg242 <= slv_reg242;
	            -- slv_reg243 <= slv_reg243;
	            -- slv_reg244 <= slv_reg244;
	            -- slv_reg245 <= slv_reg245;
	            -- slv_reg246 <= slv_reg246;
	            -- slv_reg247 <= slv_reg247;
	            -- slv_reg248 <= slv_reg248;
	            -- slv_reg249 <= slv_reg249;
	            -- slv_reg250 <= slv_reg250;
	            -- slv_reg251 <= slv_reg251;
	            -- slv_reg252 <= slv_reg252;
	            -- slv_reg253 <= slv_reg253;
	            -- slv_reg254 <= slv_reg254;
	            -- slv_reg255 <= slv_reg255;
	            -- slv_reg256 <= slv_reg256;
	            -- slv_reg257 <= slv_reg257;
	            -- slv_reg258 <= slv_reg258;
	            -- slv_reg259 <= slv_reg259;
	            -- slv_reg260 <= slv_reg260;
	            -- slv_reg261 <= slv_reg261;
	            -- slv_reg262 <= slv_reg262;
	            -- slv_reg263 <= slv_reg263;
	            -- slv_reg264 <= slv_reg264;
	            -- slv_reg265 <= slv_reg265;
	            -- slv_reg266 <= slv_reg266;
	            -- slv_reg267 <= slv_reg267;
	            -- slv_reg268 <= slv_reg268;
	            -- slv_reg269 <= slv_reg269;
	            -- slv_reg270 <= slv_reg270;
	            -- slv_reg271 <= slv_reg271;
	            -- slv_reg272 <= slv_reg272;
	            -- slv_reg273 <= slv_reg273;
	            -- slv_reg274 <= slv_reg274;
	            -- slv_reg275 <= slv_reg275;
	            -- slv_reg276 <= slv_reg276;
	            -- slv_reg277 <= slv_reg277;
	            -- slv_reg278 <= slv_reg278;
	            -- slv_reg279 <= slv_reg279;
	            -- slv_reg280 <= slv_reg280;
	            -- slv_reg281 <= slv_reg281;
	            -- slv_reg282 <= slv_reg282;
	            -- slv_reg283 <= slv_reg283;
	            -- slv_reg284 <= slv_reg284;
	            -- slv_reg285 <= slv_reg285;
	            -- slv_reg286 <= slv_reg286;
	            -- slv_reg287 <= slv_reg287;
	            -- slv_reg288 <= slv_reg288;
	            -- slv_reg289 <= slv_reg289;
	            -- slv_reg290 <= slv_reg290;
	            -- slv_reg291 <= slv_reg291;
	            -- slv_reg292 <= slv_reg292;
	            -- slv_reg293 <= slv_reg293;
	            -- slv_reg294 <= slv_reg294;
	            -- slv_reg295 <= slv_reg295;
	            -- slv_reg296 <= slv_reg296;
	            -- slv_reg297 <= slv_reg297;
	            -- slv_reg298 <= slv_reg298;
	            -- slv_reg299 <= slv_reg299;
	            -- slv_reg300 <= slv_reg300;
	            -- slv_reg301 <= slv_reg301;
	            -- slv_reg302 <= slv_reg302;
	            -- slv_reg303 <= slv_reg303;
	            -- slv_reg304 <= slv_reg304;
	            -- slv_reg305 <= slv_reg305;
	            -- slv_reg306 <= slv_reg306;
	            -- slv_reg307 <= slv_reg307;
	            -- slv_reg308 <= slv_reg308;
	            -- slv_reg309 <= slv_reg309;
	            -- slv_reg310 <= slv_reg310;
	            -- slv_reg311 <= slv_reg311;
	            -- slv_reg312 <= slv_reg312;
	            -- slv_reg313 <= slv_reg313;
	            -- slv_reg314 <= slv_reg314;
	            -- slv_reg315 <= slv_reg315;
	            -- slv_reg316 <= slv_reg316;
	            -- slv_reg317 <= slv_reg317;
	            -- slv_reg318 <= slv_reg318;
	            -- slv_reg319 <= slv_reg319;
	            -- slv_reg320 <= slv_reg320;
	            -- slv_reg321 <= slv_reg321;
	            -- slv_reg322 <= slv_reg322;
	            -- slv_reg323 <= slv_reg323;
	            -- slv_reg324 <= slv_reg324;
	            -- slv_reg325 <= slv_reg325;
	            -- slv_reg326 <= slv_reg326;
	            -- slv_reg327 <= slv_reg327;
	            -- slv_reg328 <= slv_reg328;
	            -- slv_reg329 <= slv_reg329;
	            -- slv_reg330 <= slv_reg330;
	            -- slv_reg331 <= slv_reg331;
	            -- slv_reg332 <= slv_reg332;
	            -- slv_reg333 <= slv_reg333;
	            -- slv_reg334 <= slv_reg334;
	            -- slv_reg335 <= slv_reg335;
	            -- slv_reg336 <= slv_reg336;
	            -- slv_reg337 <= slv_reg337;
	            -- slv_reg338 <= slv_reg338;
	            -- slv_reg339 <= slv_reg339;
	            -- slv_reg340 <= slv_reg340;
	            -- slv_reg341 <= slv_reg341;
	            -- slv_reg342 <= slv_reg342;
	            -- slv_reg343 <= slv_reg343;
	            -- slv_reg344 <= slv_reg344;
	            -- slv_reg345 <= slv_reg345;
	            -- slv_reg346 <= slv_reg346;
	            -- slv_reg347 <= slv_reg347;
	            -- slv_reg348 <= slv_reg348;
	            -- slv_reg349 <= slv_reg349;
	        end case;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00"; 
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arready generation
	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when S_AXI_ARVALID is 
	-- asserted. axi_araddr is reset to zero on reset assertion.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
	        -- Read Address latching 
	        axi_araddr  <= S_AXI_ARADDR;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_rvalid <= '0';
	      axi_rresp  <= "00";
	    else
	      if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
	        -- Valid read data is available at the read data bus
	        axi_rvalid <= '1';
	        axi_rresp  <= "00"; -- 'OKAY' response
	      elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
	        -- Read data is accepted by the master
	        axi_rvalid <= '0';
	      end if;            
	    end if;
	  end if;
	end process;

	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

	process (slv_reg0, slv_reg1, slv_reg2, slv_reg3, slv_reg4, slv_reg5, slv_reg6, slv_reg7, slv_reg8, slv_reg9, slv_reg10, slv_reg11, slv_reg12, slv_reg13, slv_reg14, slv_reg15, slv_reg16, slv_reg17, slv_reg18, slv_reg19, slv_reg20, slv_reg21, slv_reg22, slv_reg23, slv_reg24, slv_reg25, slv_reg26, slv_reg27, slv_reg28, slv_reg29, slv_reg30, slv_reg31, slv_reg32, slv_reg33, slv_reg34, slv_reg35, slv_reg36, slv_reg37, slv_reg38, slv_reg39, slv_reg40, slv_reg41, slv_reg42, slv_reg43, slv_reg44, slv_reg45, slv_reg46, slv_reg47, slv_reg48, slv_reg49, slv_reg50, slv_reg51, slv_reg52, slv_reg53, slv_reg54, slv_reg55, slv_reg56, slv_reg57, slv_reg58, slv_reg59, slv_reg60, slv_reg61, slv_reg62, slv_reg63, slv_reg64, slv_reg65, slv_reg66, slv_reg67, slv_reg68, slv_reg69, slv_reg70, slv_reg71, slv_reg72, slv_reg73, slv_reg74, slv_reg75, slv_reg76, slv_reg77, slv_reg78, slv_reg79, slv_reg80, slv_reg81, slv_reg82, slv_reg83, slv_reg84, slv_reg85, slv_reg86, slv_reg87, slv_reg88, slv_reg89, slv_reg90, slv_reg91, slv_reg92, slv_reg93, slv_reg94, slv_reg95, slv_reg96, slv_reg97, slv_reg98, slv_reg99, slv_reg100, slv_reg101, slv_reg102, slv_reg103, slv_reg104, slv_reg105, slv_reg106, slv_reg107, slv_reg108, slv_reg109, slv_reg110, slv_reg111, slv_reg112, slv_reg113, slv_reg114, slv_reg115, slv_reg116, slv_reg117, slv_reg118, slv_reg119, slv_reg120, slv_reg121, slv_reg122, slv_reg123, slv_reg124, slv_reg125, slv_reg126, slv_reg127, slv_reg128, slv_reg129, slv_reg130, slv_reg131, slv_reg132, slv_reg133, slv_reg134, slv_reg135, slv_reg136, slv_reg137, slv_reg138, slv_reg139, slv_reg140, slv_reg141, slv_reg142, slv_reg143, slv_reg144, slv_reg145, slv_reg146, slv_reg147, slv_reg148, slv_reg149, slv_reg150, slv_reg151, slv_reg152, slv_reg153, slv_reg154, slv_reg155, slv_reg156, slv_reg157, slv_reg158, slv_reg159, slv_reg160, slv_reg161, slv_reg162, slv_reg163, slv_reg164, slv_reg165, slv_reg166, slv_reg167, slv_reg168, slv_reg169, slv_reg170, slv_reg171, slv_reg172, slv_reg173, slv_reg174, slv_reg175, slv_reg176, slv_reg177, slv_reg178, slv_reg179, slv_reg180, slv_reg181, slv_reg182, slv_reg183, slv_reg184, slv_reg185, slv_reg186, slv_reg187, slv_reg188, slv_reg189, slv_reg190, slv_reg191, slv_reg192, slv_reg193, slv_reg194, slv_reg195, slv_reg196, slv_reg197, slv_reg198, slv_reg199, slv_reg200, slv_reg201, slv_reg202, slv_reg203, slv_reg204, slv_reg205, slv_reg206, slv_reg207, slv_reg208, slv_reg209, slv_reg210, slv_reg211, slv_reg212, slv_reg213, slv_reg214, slv_reg215, slv_reg216, slv_reg217, slv_reg218, slv_reg219, slv_reg220, slv_reg221, slv_reg222, slv_reg223, slv_reg224, slv_reg225, slv_reg226, slv_reg227, slv_reg228, slv_reg229, slv_reg230, slv_reg231, slv_reg232, slv_reg233, slv_reg234, slv_reg235, slv_reg236, slv_reg237, slv_reg238, slv_reg239, slv_reg240, slv_reg241, slv_reg242, slv_reg243, slv_reg244, slv_reg245, slv_reg246, slv_reg247, slv_reg248, slv_reg249, slv_reg250, slv_reg251, slv_reg252, slv_reg253, slv_reg254, slv_reg255, slv_reg256, slv_reg257, slv_reg258, slv_reg259, slv_reg260, slv_reg261, slv_reg262, slv_reg263, slv_reg264, slv_reg265, slv_reg266, slv_reg267, slv_reg268, slv_reg269, slv_reg270, slv_reg271, slv_reg272, slv_reg273, slv_reg274, slv_reg275, slv_reg276, slv_reg277, slv_reg278, slv_reg279, slv_reg280, slv_reg281, slv_reg282, slv_reg283, slv_reg284, slv_reg285, slv_reg286, slv_reg287, slv_reg288, slv_reg289, slv_reg290, slv_reg291, slv_reg292, slv_reg293, slv_reg294, slv_reg295, slv_reg296, slv_reg297, slv_reg298, slv_reg299, slv_reg300, slv_reg301, slv_reg302, slv_reg303, slv_reg304, slv_reg305, slv_reg306, slv_reg307, slv_reg308, slv_reg309, slv_reg310, slv_reg311, slv_reg312, slv_reg313, slv_reg314, slv_reg315, slv_reg316, slv_reg317, slv_reg318, slv_reg319, slv_reg320, slv_reg321, slv_reg322, slv_reg323, slv_reg324, slv_reg325, slv_reg326, slv_reg327, slv_reg328, slv_reg329, slv_reg330, slv_reg331, slv_reg332, slv_reg333, slv_reg334, slv_reg335, slv_reg336, slv_reg337, slv_reg338, slv_reg339, slv_reg340, slv_reg341, slv_reg342, slv_reg343, slv_reg344, slv_reg345, slv_reg346, slv_reg347, slv_reg348, slv_reg349, axi_araddr, S_AXI_ARESETN, slv_reg_rden)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
	    -- Address decoding for reading registers
	    loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	    case loc_addr is
	      when b"000000000" =>
	        reg_data_out <= slv_reg0;
	      when b"000000001" =>
	        reg_data_out <= slv_reg1;
	      when b"000000010" =>
	        reg_data_out <= slv_reg2;
	      when b"000000011" =>
	        reg_data_out <= slv_reg3;
	      when b"000000100" =>
	        reg_data_out <= slv_reg4;
	      when b"000000101" =>
	        reg_data_out <= slv_reg5;
	      when b"000000110" =>
	        reg_data_out <= slv_reg6;
	      when b"000000111" =>
	        reg_data_out <= slv_reg7;
	      when b"000001000" =>
	        reg_data_out <= slv_reg8;
	      when b"000001001" =>
	        reg_data_out <= slv_reg9;
	      when b"000001010" =>
	        reg_data_out <= slv_reg10;
	      when b"000001011" =>
	        reg_data_out <= slv_reg11;
	      when b"000001100" =>
	        reg_data_out <= slv_reg12;
	      when b"000001101" =>
	        reg_data_out <= slv_reg13;
	      when b"000001110" =>
	        reg_data_out <= slv_reg14;
	      when b"000001111" =>
	        reg_data_out <= slv_reg15;
	      when b"000010000" =>
	        reg_data_out <= slv_reg16;
	      when b"000010001" =>
	        reg_data_out <= slv_reg17;
	      when b"000010010" =>
	        reg_data_out <= slv_reg18;
	      when b"000010011" =>
	        reg_data_out <= slv_reg19;
	      when b"000010100" =>
	        reg_data_out <= slv_reg20;
	      when b"000010101" =>
	        reg_data_out <= slv_reg21;
	      when b"000010110" =>
	        reg_data_out <= slv_reg22;
	      when b"000010111" =>
	        reg_data_out <= slv_reg23;
	      when b"000011000" =>
	        reg_data_out <= slv_reg24;
	      when b"000011001" =>
	        reg_data_out <= slv_reg25;
	      when b"000011010" =>
	        reg_data_out <= slv_reg26;
	      when b"000011011" =>
	        reg_data_out <= slv_reg27;
	      when b"000011100" =>
	        reg_data_out <= slv_reg28;
	      when b"000011101" =>
	        reg_data_out <= slv_reg29;
	      when b"000011110" =>
	        reg_data_out <= slv_reg30;
	      when b"000011111" =>
	        reg_data_out <= slv_reg31;
	      when b"000100000" =>
	        reg_data_out <= slv_reg32;
	      when b"000100001" =>
	        reg_data_out <= slv_reg33;
	      when b"000100010" =>
	        reg_data_out <= slv_reg34;
	      when b"000100011" =>
	        reg_data_out <= slv_reg35;
	      when b"000100100" =>
	        reg_data_out <= slv_reg36;
	      when b"000100101" =>
	        reg_data_out <= slv_reg37;
	      when b"000100110" =>
	        reg_data_out <= slv_reg38;
	      when b"000100111" =>
	        reg_data_out <= slv_reg39;
	      when b"000101000" =>
	        reg_data_out <= slv_reg40;
	      when b"000101001" =>
	        reg_data_out <= slv_reg41;
	      when b"000101010" =>
	        reg_data_out <= slv_reg42;
	      when b"000101011" =>
	        reg_data_out <= slv_reg43;
	      when b"000101100" =>
	        reg_data_out <= slv_reg44;
	      when b"000101101" =>
	        reg_data_out <= slv_reg45;
	      when b"000101110" =>
	        reg_data_out <= slv_reg46;
	      when b"000101111" =>
	        reg_data_out <= slv_reg47;
	      when b"000110000" =>
	        reg_data_out <= slv_reg48;
	      when b"000110001" =>
	        reg_data_out <= slv_reg49;
	      when b"000110010" =>
	        reg_data_out <= slv_reg50;
	      when b"000110011" =>
	        reg_data_out <= slv_reg51;
	      when b"000110100" =>
	        reg_data_out <= slv_reg52;
	      when b"000110101" =>
	        reg_data_out <= slv_reg53;
	      when b"000110110" =>
	        reg_data_out <= slv_reg54;
	      when b"000110111" =>
	        reg_data_out <= slv_reg55;
	      when b"000111000" =>
	        reg_data_out <= slv_reg56;
	      when b"000111001" =>
	        reg_data_out <= slv_reg57;
	      when b"000111010" =>
	        reg_data_out <= slv_reg58;
	      when b"000111011" =>
	        reg_data_out <= slv_reg59;
	      when b"000111100" =>
	        reg_data_out <= slv_reg60;
	      when b"000111101" =>
	        reg_data_out <= slv_reg61;
	      when b"000111110" =>
	        reg_data_out <= slv_reg62;
	      when b"000111111" =>
	        reg_data_out <= slv_reg63;
	      when b"001000000" =>
	        reg_data_out <= slv_reg64;
	      when b"001000001" =>
	        reg_data_out <= slv_reg65;
	      when b"001000010" =>
	        reg_data_out <= slv_reg66;
	      when b"001000011" =>
	        reg_data_out <= slv_reg67;
	      when b"001000100" =>
	        reg_data_out <= slv_reg68;
	      when b"001000101" =>
	        reg_data_out <= slv_reg69;
	      when b"001000110" =>
	        reg_data_out <= slv_reg70;
	      when b"001000111" =>
	        reg_data_out <= slv_reg71;
	      when b"001001000" =>
	        reg_data_out <= slv_reg72;
	      when b"001001001" =>
	        reg_data_out <= slv_reg73;
	      when b"001001010" =>
	        reg_data_out <= slv_reg74;
	      when b"001001011" =>
	        reg_data_out <= slv_reg75;
	      when b"001001100" =>
	        reg_data_out <= slv_reg76;
	      when b"001001101" =>
	        reg_data_out <= slv_reg77;
	      when b"001001110" =>
	        reg_data_out <= slv_reg78;
	      when b"001001111" =>
	        reg_data_out <= slv_reg79;
	      when b"001010000" =>
	        reg_data_out <= slv_reg80;
	      when b"001010001" =>
	        reg_data_out <= slv_reg81;
	      when b"001010010" =>
	        reg_data_out <= slv_reg82;
	      when b"001010011" =>
	        reg_data_out <= slv_reg83;
	      when b"001010100" =>
	        reg_data_out <= slv_reg84;
	      when b"001010101" =>
	        reg_data_out <= slv_reg85;
	      when b"001010110" =>
	        reg_data_out <= slv_reg86;
	      when b"001010111" =>
	        reg_data_out <= slv_reg87;
	      when b"001011000" =>
	        reg_data_out <= slv_reg88;
	      when b"001011001" =>
	        reg_data_out <= slv_reg89;
	      when b"001011010" =>
	        reg_data_out <= slv_reg90;
	      when b"001011011" =>
	        reg_data_out <= slv_reg91;
	      when b"001011100" =>
	        reg_data_out <= slv_reg92;
	      when b"001011101" =>
	        reg_data_out <= slv_reg93;
	      when b"001011110" =>
	        reg_data_out <= slv_reg94;
	      when b"001011111" =>
	        reg_data_out <= slv_reg95;
	      when b"001100000" =>
	        reg_data_out <= slv_reg96;
	      when b"001100001" =>
	        reg_data_out <= slv_reg97;
	      when b"001100010" =>
	        reg_data_out <= slv_reg98;
	      when b"001100011" =>
	        reg_data_out <= slv_reg99;
	      when b"001100100" =>
	        reg_data_out <= slv_reg100;
	      when b"001100101" =>
	        reg_data_out <= slv_reg101;
	      when b"001100110" =>
	        reg_data_out <= slv_reg102;
	      when b"001100111" =>
	        reg_data_out <= slv_reg103;
	      when b"001101000" =>
	        reg_data_out <= slv_reg104;
	      when b"001101001" =>
	        reg_data_out <= slv_reg105;
	      when b"001101010" =>
	        reg_data_out <= slv_reg106;
	      when b"001101011" =>
	        reg_data_out <= slv_reg107;
	      when b"001101100" =>
	        reg_data_out <= slv_reg108;
	      when b"001101101" =>
	        reg_data_out <= slv_reg109;
	      when b"001101110" =>
	        reg_data_out <= slv_reg110;
	      when b"001101111" =>
	        reg_data_out <= slv_reg111;
	      when b"001110000" =>
	        reg_data_out <= slv_reg112;
	      when b"001110001" =>
	        reg_data_out <= slv_reg113;
	      when b"001110010" =>
	        reg_data_out <= slv_reg114;
	      when b"001110011" =>
	        reg_data_out <= slv_reg115;
	      when b"001110100" =>
	        reg_data_out <= slv_reg116;
	      when b"001110101" =>
	        reg_data_out <= slv_reg117;
	      when b"001110110" =>
	        reg_data_out <= slv_reg118;
	      when b"001110111" =>
	        reg_data_out <= slv_reg119;
	      when b"001111000" =>
	        reg_data_out <= slv_reg120;
	      when b"001111001" =>
	        reg_data_out <= slv_reg121;
	      when b"001111010" =>
	        reg_data_out <= slv_reg122;
	      when b"001111011" =>
	        reg_data_out <= slv_reg123;
	      when b"001111100" =>
	        reg_data_out <= slv_reg124;
	      when b"001111101" =>
	        reg_data_out <= slv_reg125;
	      when b"001111110" =>
	        reg_data_out <= slv_reg126;
	      when b"001111111" =>
	        reg_data_out <= slv_reg127;
	      when b"010000000" =>
	        reg_data_out <= slv_reg128;
	      when b"010000001" =>
	        reg_data_out <= slv_reg129;
	      when b"010000010" =>
	        reg_data_out <= slv_reg130;
	      when b"010000011" =>
	        reg_data_out <= slv_reg131;
	      when b"010000100" =>
	        reg_data_out <= slv_reg132;
	      when b"010000101" =>
	        reg_data_out <= slv_reg133;
	      when b"010000110" =>
	        reg_data_out <= slv_reg134;
	      when b"010000111" =>
	        reg_data_out <= slv_reg135;
	      when b"010001000" =>
	        reg_data_out <= slv_reg136;
	      when b"010001001" =>
	        reg_data_out <= slv_reg137;
	      when b"010001010" =>
	        reg_data_out <= slv_reg138;
	      when b"010001011" =>
	        reg_data_out <= slv_reg139;
	      when b"010001100" =>
	        reg_data_out <= slv_reg140;
	      when b"010001101" =>
	        reg_data_out <= slv_reg141;
	      when b"010001110" =>
	        reg_data_out <= slv_reg142;
	      when b"010001111" =>
	        reg_data_out <= slv_reg143;
	      when b"010010000" =>
	        reg_data_out <= slv_reg144;
	      when b"010010001" =>
	        reg_data_out <= slv_reg145;
	      when b"010010010" =>
	        reg_data_out <= slv_reg146;
	      when b"010010011" =>
	        reg_data_out <= slv_reg147;
	      when b"010010100" =>
	        reg_data_out <= slv_reg148;
	      when b"010010101" =>
	        reg_data_out <= slv_reg149;
	      when b"010010110" =>
	        reg_data_out <= slv_reg150;
	      when b"010010111" =>
	        reg_data_out <= slv_reg151;
	      when b"010011000" =>
	        reg_data_out <= slv_reg152;
	      when b"010011001" =>
	        reg_data_out <= slv_reg153;
	      when b"010011010" =>
	        reg_data_out <= slv_reg154;
	      when b"010011011" =>
	        reg_data_out <= slv_reg155;
	      when b"010011100" =>
	        reg_data_out <= slv_reg156;
	      when b"010011101" =>
	        reg_data_out <= slv_reg157;
	      when b"010011110" =>
	        reg_data_out <= slv_reg158;
	      when b"010011111" =>
	        reg_data_out <= slv_reg159;
	      when b"010100000" =>
	        reg_data_out <= slv_reg160;
	      when b"010100001" =>
	        reg_data_out <= slv_reg161;
	      when b"010100010" =>
	        reg_data_out <= slv_reg162;
	      when b"010100011" =>
	        reg_data_out <= slv_reg163;
	      when b"010100100" =>
	        reg_data_out <= slv_reg164;
	      when b"010100101" =>
	        reg_data_out <= slv_reg165;
	      when b"010100110" =>
	        reg_data_out <= slv_reg166;
	      when b"010100111" =>
	        reg_data_out <= slv_reg167;
	      when b"010101000" =>
	        reg_data_out <= slv_reg168;
	      when b"010101001" =>
	        reg_data_out <= slv_reg169;
	      when b"010101010" =>
	        reg_data_out <= slv_reg170;
	      when b"010101011" =>
	        reg_data_out <= slv_reg171;
	      when b"010101100" =>
	        reg_data_out <= slv_reg172;
	      when b"010101101" =>
	        reg_data_out <= slv_reg173;
	      when b"010101110" =>
	        reg_data_out <= slv_reg174;
	      when b"010101111" =>
	        reg_data_out <= slv_reg175;
	      when b"010110000" =>
	        reg_data_out <= slv_reg176;
	      when b"010110001" =>
	        reg_data_out <= slv_reg177;
	      when b"010110010" =>
	        reg_data_out <= slv_reg178;
	      when b"010110011" =>
	        reg_data_out <= slv_reg179;
	      when b"010110100" =>
	        reg_data_out <= slv_reg180;
	      when b"010110101" =>
	        reg_data_out <= slv_reg181;
	      when b"010110110" =>
	        reg_data_out <= slv_reg182;
	      when b"010110111" =>
	        reg_data_out <= slv_reg183;
	      when b"010111000" =>
	        reg_data_out <= slv_reg184;
	      when b"010111001" =>
	        reg_data_out <= slv_reg185;
	      when b"010111010" =>
	        reg_data_out <= slv_reg186;
	      when b"010111011" =>
	        reg_data_out <= slv_reg187;
	      when b"010111100" =>
	        reg_data_out <= slv_reg188;
	      when b"010111101" =>
	        reg_data_out <= slv_reg189;
	      when b"010111110" =>
	        reg_data_out <= slv_reg190;
	      when b"010111111" =>
	        reg_data_out <= slv_reg191;
	      when b"011000000" =>
	        reg_data_out <= slv_reg192;
	      when b"011000001" =>
	        reg_data_out <= slv_reg193;
	      when b"011000010" =>
	        reg_data_out <= slv_reg194;
	      when b"011000011" =>
	        reg_data_out <= slv_reg195;
	      when b"011000100" =>
	        reg_data_out <= slv_reg196;
	      when b"011000101" =>
	        reg_data_out <= slv_reg197;
	      when b"011000110" =>
	        reg_data_out <= slv_reg198;
	      when b"011000111" =>
	        reg_data_out <= slv_reg199;
	      when b"011001000" =>
	        reg_data_out <= slv_reg200;
	      when b"011001001" =>
	        reg_data_out <= slv_reg201;
	      when b"011001010" =>
	        reg_data_out <= slv_reg202;
	      when b"011001011" =>
	        reg_data_out <= slv_reg203;
	      when b"011001100" =>
	        reg_data_out <= slv_reg204;
	      when b"011001101" =>
	        reg_data_out <= slv_reg205;
	      when b"011001110" =>
	        reg_data_out <= slv_reg206;
	      when b"011001111" =>
	        reg_data_out <= slv_reg207;
	      when b"011010000" =>
	        reg_data_out <= slv_reg208;
	      when b"011010001" =>
	        reg_data_out <= slv_reg209;
	      when b"011010010" =>
	        reg_data_out <= slv_reg210;
	      when b"011010011" =>
	        reg_data_out <= slv_reg211;
	      when b"011010100" =>
	        reg_data_out <= slv_reg212;
	      when b"011010101" =>
	        reg_data_out <= slv_reg213;
	      when b"011010110" =>
	        reg_data_out <= slv_reg214;
	      when b"011010111" =>
	        reg_data_out <= slv_reg215;
	      when b"011011000" =>
	        reg_data_out <= slv_reg216;
	      when b"011011001" =>
	        reg_data_out <= slv_reg217;
	      when b"011011010" =>
	        reg_data_out <= slv_reg218;
	      when b"011011011" =>
	        reg_data_out <= slv_reg219;
	      when b"011011100" =>
	        reg_data_out <= slv_reg220;
	      when b"011011101" =>
	        reg_data_out <= slv_reg221;
	      when b"011011110" =>
	        reg_data_out <= slv_reg222;
	      when b"011011111" =>
	        reg_data_out <= slv_reg223;
	      when b"011100000" =>
	        reg_data_out <= slv_reg224;
	      when b"011100001" =>
	        reg_data_out <= slv_reg225;
	      when b"011100010" =>
	        reg_data_out <= slv_reg226;
	      when b"011100011" =>
	        reg_data_out <= slv_reg227;
	      when b"011100100" =>
	        reg_data_out <= slv_reg228;
	      when b"011100101" =>
	        reg_data_out <= slv_reg229;
	      when b"011100110" =>
	        reg_data_out <= slv_reg230;
	      when b"011100111" =>
	        reg_data_out <= slv_reg231;
	      when b"011101000" =>
	        reg_data_out <= slv_reg232;
	      when b"011101001" =>
	        reg_data_out <= slv_reg233;
	      when b"011101010" =>
	        reg_data_out <= slv_reg234;
	      when b"011101011" =>
	        reg_data_out <= slv_reg235;
	      when b"011101100" =>
	        reg_data_out <= slv_reg236;
	      when b"011101101" =>
	        reg_data_out <= slv_reg237;
	      when b"011101110" =>
	        reg_data_out <= slv_reg238;
	      when b"011101111" =>
	        reg_data_out <= slv_reg239;
	      when b"011110000" =>
	        reg_data_out <= slv_reg240;
	      when b"011110001" =>
	        reg_data_out <= slv_reg241;
	      when b"011110010" =>
	        reg_data_out <= slv_reg242;
	      when b"011110011" =>
	        reg_data_out <= slv_reg243;
	      when b"011110100" =>
	        reg_data_out <= slv_reg244;
	      when b"011110101" =>
	        reg_data_out <= slv_reg245;
	      when b"011110110" =>
	        reg_data_out <= slv_reg246;
	      when b"011110111" =>
	        reg_data_out <= slv_reg247;
	      when b"011111000" =>
	        reg_data_out <= slv_reg248;
	      when b"011111001" =>
	        reg_data_out <= slv_reg249;
	      when b"011111010" =>
	        reg_data_out <= slv_reg250;
	      when b"011111011" =>
	        reg_data_out <= slv_reg251;
	      when b"011111100" =>
	        reg_data_out <= slv_reg252;
	      when b"011111101" =>
	        reg_data_out <= slv_reg253;
	      when b"011111110" =>
	        reg_data_out <= slv_reg254;
	      when b"011111111" =>
	        reg_data_out <= slv_reg255;
	      when b"100000000" =>
	        reg_data_out <= slv_reg256;
	      when b"100000001" =>
	        reg_data_out <= slv_reg257;
	      when b"100000010" =>
	        reg_data_out <= slv_reg258;
	      when b"100000011" =>
	        reg_data_out <= slv_reg259;
	      when b"100000100" =>
	        reg_data_out <= slv_reg260;
	      when b"100000101" =>
	        reg_data_out <= slv_reg261;
	      when b"100000110" =>
	        reg_data_out <= slv_reg262;
	      when b"100000111" =>
	        reg_data_out <= slv_reg263;
	      when b"100001000" =>
	        reg_data_out <= slv_reg264;
	      when b"100001001" =>
	        reg_data_out <= slv_reg265;
	      when b"100001010" =>
	        reg_data_out <= slv_reg266;
	      when b"100001011" =>
	        reg_data_out <= slv_reg267;
	      when b"100001100" =>
	        reg_data_out <= slv_reg268;
	      when b"100001101" =>
	        reg_data_out <= slv_reg269;
	      when b"100001110" =>
	        reg_data_out <= slv_reg270;
	      when b"100001111" =>
	        reg_data_out <= slv_reg271;
	      when b"100010000" =>
	        reg_data_out <= slv_reg272;
	      when b"100010001" =>
	        reg_data_out <= slv_reg273;
	      when b"100010010" =>
	        reg_data_out <= slv_reg274;
	      when b"100010011" =>
	        reg_data_out <= slv_reg275;
	      when b"100010100" =>
	        reg_data_out <= slv_reg276;
	      when b"100010101" =>
	        reg_data_out <= slv_reg277;
	      when b"100010110" =>
	        reg_data_out <= slv_reg278;
	      when b"100010111" =>
	        reg_data_out <= slv_reg279;
	      when b"100011000" =>
	        reg_data_out <= slv_reg280;
	      when b"100011001" =>
	        reg_data_out <= slv_reg281;
	      when b"100011010" =>
	        reg_data_out <= slv_reg282;
	      when b"100011011" =>
	        reg_data_out <= slv_reg283;
	      when b"100011100" =>
	        reg_data_out <= slv_reg284;
	      when b"100011101" =>
	        reg_data_out <= slv_reg285;
	      when b"100011110" =>
	        reg_data_out <= slv_reg286;
	      when b"100011111" =>
	        reg_data_out <= slv_reg287;
	      when b"100100000" =>
	        reg_data_out <= slv_reg288;
	      when b"100100001" =>
	        reg_data_out <= slv_reg289;
	      when b"100100010" =>
	        reg_data_out <= slv_reg290;
	      when b"100100011" =>
	        reg_data_out <= slv_reg291;
	      when b"100100100" =>
	        reg_data_out <= slv_reg292;
	      when b"100100101" =>
	        reg_data_out <= slv_reg293;
	      when b"100100110" =>
	        reg_data_out <= slv_reg294;
	      when b"100100111" =>
	        reg_data_out <= slv_reg295;
	      when b"100101000" =>
	        reg_data_out <= slv_reg296;
	      when b"100101001" =>
	        reg_data_out <= slv_reg297;
	      when b"100101010" =>
	        reg_data_out <= slv_reg298;
	      when b"100101011" =>
	        reg_data_out <= slv_reg299;
	      when b"100101100" =>
	        reg_data_out <= slv_reg300;
	      when b"100101101" =>
	        reg_data_out <= slv_reg301;
	      when b"100101110" =>
	        reg_data_out <= slv_reg302;
	      when b"100101111" =>
	        reg_data_out <= slv_reg303;
	      when b"100110000" =>
	        reg_data_out <= slv_reg304;
	      when b"100110001" =>
	        reg_data_out <= slv_reg305;
	      when b"100110010" =>
	        reg_data_out <= slv_reg306;
	      when b"100110011" =>
	        reg_data_out <= slv_reg307;
	      when b"100110100" =>
	        reg_data_out <= slv_reg308;
	      when b"100110101" =>
	        reg_data_out <= slv_reg309;
	      when b"100110110" =>
	        reg_data_out <= slv_reg310;
	      when b"100110111" =>
	        reg_data_out <= slv_reg311;
	      when b"100111000" =>
	        reg_data_out <= slv_reg312;
	      when b"100111001" =>
	        reg_data_out <= slv_reg313;
	      when b"100111010" =>
	        reg_data_out <= slv_reg314;
	      when b"100111011" =>
	        reg_data_out <= slv_reg315;
	      when b"100111100" =>
	        reg_data_out <= slv_reg316;
	      when b"100111101" =>
	        reg_data_out <= slv_reg317;
	      when b"100111110" =>
	        reg_data_out <= slv_reg318;
	      when b"100111111" =>
	        reg_data_out <= slv_reg319;
	      when b"101000000" =>
	        reg_data_out <= slv_reg320;
	      when b"101000001" =>
	        reg_data_out <= slv_reg321;
	      when b"101000010" =>
	        reg_data_out <= slv_reg322;
	      when b"101000011" =>
	        reg_data_out <= slv_reg323;
	      when b"101000100" =>
	        reg_data_out <= slv_reg324;
	      when b"101000101" =>
	        reg_data_out <= slv_reg325;
	      when b"101000110" =>
	        reg_data_out <= slv_reg326;
	      when b"101000111" =>
	        reg_data_out <= slv_reg327;
	      when b"101001000" =>
	        reg_data_out <= slv_reg328;
	      when b"101001001" =>
	        reg_data_out <= slv_reg329;
	      when b"101001010" =>
	        reg_data_out <= slv_reg330;
	      when b"101001011" =>
	        reg_data_out <= slv_reg331;
	      when b"101001100" =>
	        reg_data_out <= slv_reg332;
	      when b"101001101" =>
	        reg_data_out <= slv_reg333;
	      when b"101001110" =>
	        reg_data_out <= slv_reg334;
	      when b"101001111" =>
	        reg_data_out <= slv_reg335;
	      when b"101010000" =>
	        reg_data_out <= slv_reg336;
	      when b"101010001" =>
	        reg_data_out <= slv_reg337;
	      when b"101010010" =>
	        reg_data_out <= slv_reg338;
	      when b"101010011" =>
	        reg_data_out <= slv_reg339;
	      when b"101010100" =>
	        reg_data_out <= slv_reg340;
	      when b"101010101" =>
	        reg_data_out <= slv_reg341;
	      when b"101010110" =>
	        reg_data_out <= slv_reg342;
	      when b"101010111" =>
	        reg_data_out <= slv_reg343;
	      when b"101011000" =>
	        reg_data_out <= slv_reg344;
	      when b"101011001" =>
	        reg_data_out <= slv_reg345;
	      when b"101011010" =>
	        reg_data_out <= slv_reg346;
	      when b"101011011" =>
	        reg_data_out <= slv_reg347;
	      when b"101011100" =>
	        reg_data_out <= slv_reg348;
	      when b"101011101" =>
	        reg_data_out <= slv_reg349;
	      when others =>
	        reg_data_out  <= (others => '0');
	    end case;
	end process; 

	-- Output register or memory read data
	process( S_AXI_ACLK ) is
	begin
	  if (rising_edge (S_AXI_ACLK)) then
	    if ( S_AXI_ARESETN = '0' ) then
	      axi_rdata  <= (others => '0');
	    else
	      if (slv_reg_rden = '1') then
	        -- When there is a valid read address (S_AXI_ARVALID) with 
	        -- acceptance of read address by the slave (axi_arready), 
	        -- output the read dada 
	        -- Read address mux
	          axi_rdata <= reg_data_out;     -- register read data
	      end if;   
	    end if;
	  end if;
	end process;


	-- Add user logic here
process (S_AXI_ACLK)
begin
    if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
        start <= slv_reg2(0);
     end if;
end process;
 
--    quantity_keccak_cycle <= slv_reg1;

--order theta, pi, rho, chi, iota
    theta_in<=round_in;
    pi_in<=rho_out;
    rho_in<=theta_out;
    chi_in<=pi_out;
    iota_in<=chi_out;
    round_out<=iota_out;


    --chi
    i0000: for x in 0 to 2 generate
        i0001: for y in 0 to 4 generate
            i0002: for i in 0 to 63 generate
                chi_out(x)(y)(i)<=chi_in(x)(y)(i) xor  ( (chi_in(x+1)(y)(i) xor '1')and chi_in(x+2)(y)(i));
            end generate;    
        end generate;
    end generate;

    i0011: for y in 0 to 4 generate
        i0021: for i in 0 to 63 generate
            chi_out(3)(y)(i)<=chi_in(3)(y)(i) xor  ( (chi_in(4)(y)(i) xor '1')and chi_in(0)(y)(i));            
        end generate;    
    end generate;
        
    i0012: for y in 0 to 4 generate
        i0022: for i in 0 to 63 generate
            chi_out(4)(y)(i)<=chi_in(4)(y)(i) xor  ( (chi_in(0)(y)(i) xor '1')and chi_in(1)(y)(i));        
        end generate;    
    end generate;
    
    --theta
    --compute sum of columns
    i0101: for x in 0 to 4 generate
        i0102: for i in 0 to 63 generate
            sum_sheet(x)(i)<=theta_in(x)(0)(i) xor theta_in(x)(1)(i) xor theta_in(x)(2)(i) xor theta_in(x)(3)(i) xor theta_in(x)(4)(i);
        end generate;    
    end generate;

    i0200: for x in 1 to 3 generate
        i0201: for y in 0 to 4 generate
            theta_out(x)(y)(0)<=theta_in(x)(y)(0) xor sum_sheet(x-1)(0) xor sum_sheet(x+1)(63);
            i0202: for i in 1 to 63 generate
                    theta_out(x)(y)(i)<=theta_in(x)(y)(i) xor sum_sheet(x-1)(i) xor sum_sheet(x+1)(i-1);
            end generate;    
        end generate;
    end generate;

    i2001: for y in 0 to 4 generate
        theta_out(0)(y)(0)<=theta_in(0)(y)(0) xor sum_sheet(4)(0) xor sum_sheet(1)(63);
        i2021: for i in 1 to 63 generate
                theta_out(0)(y)(i)<=theta_in(0)(y)(i) xor sum_sheet(4)(i) xor sum_sheet(1)(i-1);
        end generate;    
    end generate;

    i2002: for y in 0 to 4 generate
        theta_out(4)(y)(0)<=theta_in(4)(y)(0) xor sum_sheet(3)(0) xor sum_sheet(0)(63);
        i2022: for i in 1 to 63 generate
                theta_out(4)(y)(i)<=theta_in(4)(y)(i) xor sum_sheet(3)(i) xor sum_sheet(0)(i-1);
        end generate;    
    end generate;

    -- pi
    i3001: for x in 0 to 4 generate
        i3002: for y in 0 to 4 generate
            i3003: for i in 0 to 63 generate
				pi_out(x)(y)(i)<=pi_in((x+3*y)mod 5)(x)(i);
            end generate;    
        end generate;
    end generate;

    --rho
    i4001: for i in 0 to 63 generate
            rho_out(0)(0)(i)<=rho_in(0)(0)(i);
    end generate;    
    i4002: for i in 0 to 63 generate
            rho_out(0)(1)(i)<=rho_in(0)(1)((i-1)mod 64);
    end generate;
    i4003: for i in 0 to 63 generate
            rho_out(0)(2)(i)<=rho_in(0)(2)((i-62)mod 64);
    end generate;
    i4004: for i in 0 to 63 generate
            rho_out(0)(3)(i)<=rho_in(0)(3)((i-28)mod 64);
    end generate;
    i4005: for i in 0 to 63 generate
            rho_out(0)(4)(i)<=rho_in(0)(4)((i-27)mod 64);
    end generate;

    i4011: for i in 0 to 63 generate
            rho_out(1)(0)(i)<=rho_in(1)(0)((i-36)mod 64);
    end generate;    
    i4012: for i in 0 to 63 generate
            rho_out(1)(1)(i)<=rho_in(1)(1)((i-44)mod 64);
    end generate;
    i4013: for i in 0 to 63 generate
            rho_out(1)(2)(i)<=rho_in(1)(2)((i-6)mod 64);
    end generate;
    i4014: for i in 0 to 63 generate
            rho_out(1)(3)(i)<=rho_in(1)(3)((i-55)mod 64);
    end generate;
    i4015: for i in 0 to 63 generate
            rho_out(1)(4)(i)<=rho_in(1)(4)((i-20)mod 64);
    end generate;

    i4021: for i in 0 to 63 generate
            rho_out(2)(0)(i)<=rho_in(2)(0)((i-3)mod 64);
    end generate;    
    i4022: for i in 0 to 63 generate
            rho_out(2)(1)(i)<=rho_in(2)(1)((i-10)mod 64);
    end generate;
    i4023: for i in 0 to 63 generate
            rho_out(2)(2)(i)<=rho_in(2)(2)((i-43)mod 64);
    end generate;
    i4024: for i in 0 to 63 generate
            rho_out(2)(3)(i)<=rho_in(2)(3)((i-25)mod 64);
    end generate;
    i4025: for i in 0 to 63 generate
            rho_out(2)(4)(i)<=rho_in(2)(4)((i-39)mod 64);
    end generate;

    i4031: for i in 0 to 63 generate
            rho_out(3)(0)(i)<=rho_in(3)(0)((i-41)mod 64);
    end generate;    
    i4032: for i in 0 to 63 generate
            rho_out(3)(1)(i)<=rho_in(3)(1)((i-45)mod 64);
    end generate;
    i4033: for i in 0 to 63 generate
            rho_out(3)(2)(i)<=rho_in(3)(2)((i-15)mod 64);
    end generate;
    i4034: for i in 0 to 63 generate
            rho_out(3)(3)(i)<=rho_in(3)(3)((i-21)mod 64);
    end generate;
    i4035: for i in 0 to 63 generate
            rho_out(3)(4)(i)<=rho_in(3)(4)((i-8)mod 64);
    end generate;

    i4041: for i in 0 to 63 generate
            rho_out(4)(0)(i)<=rho_in(4)(0)((i-18)mod 64);
    end generate;    
    i4042: for i in 0 to 63 generate
            rho_out(4)(1)(i)<=rho_in(4)(1)((i-2)mod 64);
    end generate;
    i4043: for i in 0 to 63 generate
            rho_out(4)(2)(i)<=rho_in(4)(2)((i-61)mod 64);
    end generate;
    i4044: for i in 0 to 63 generate
            rho_out(4)(3)(i)<=rho_in(4)(3)((i-56)mod 64);
    end generate;
    i4045: for i in 0 to 63 generate
            rho_out(4)(4)(i)<=rho_in(4)(4)((i-14)mod 64);
    end generate;

    --iota
    i5001: for x in 1 to 4 generate
        i5002: for y in 0 to 4 generate
            i5003: for i in 0 to 63 generate
                    iota_out(x)(y)(i)<=iota_in(x)(y)(i);
            end generate;    
        end generate;
    end generate;


    i5012: for y in 1 to 4 generate
        i5013: for i in 0 to 63 generate
                 iota_out(0)(y)(i)<=iota_in(0)(y)(i);
        end generate;    
    end generate;

    i5103: for i in 0 to 63 generate
              iota_out(0)(0)(i)<=iota_in(0)(0)(i) xor signal_temp(i);
        end generate;  

      
-- signal_temp<=round_constant_signal;
--constant_map:    round_constant port map(
--        counter_nr_rounds,
--        round_constant_signal
--    );
--counter_nr_rounds<="00000";
process (S_AXI_ACLK) is 
begin
if(S_AXI_ACLK'event and S_AXI_ACLK='0') then
    case counter_nr_rounds is
    when "00000" => signal_temp <= X"0000000000000001" ;
    when "00001" => signal_temp <= X"0000000000008082" ;
    when "00010" => signal_temp <= X"800000000000808A" ;
    when "00011" => signal_temp <= X"8000000080008000" ;
    when "00100" => signal_temp <= X"000000000000808B" ;
    when "00101" => signal_temp <= X"0000000080000001" ;
    when "00110" => signal_temp <= X"8000000080008081" ;
    when "00111" => signal_temp <= X"8000000000008009" ;
    when "01000" => signal_temp <= X"000000000000008A" ;
    when "01001" => signal_temp <= X"0000000000000088" ;
    when "01010" => signal_temp <= X"0000000080008009" ;
    when "01011" => signal_temp <= X"000000008000000A" ;
    when "01100" => signal_temp <= X"000000008000808B" ;
    when "01101" => signal_temp <= X"800000000000008B" ;
    when "01110" => signal_temp <= X"8000000000008089" ;
    when "01111" => signal_temp <= X"8000000000008003" ;
    when "10000" => signal_temp <= X"8000000000008002" ;
    when "10001" => signal_temp <= X"8000000000000080" ;
    when "10010" => signal_temp <= X"000000000000800A" ;
    when "10011" => signal_temp <= X"800000008000000A" ;
    when "10100" => signal_temp <= X"8000000080008081" ;
    when "10101" => signal_temp <= X"8000000000008080" ;
    when "10110" => signal_temp <= X"0000000080000001" ;
    when "10111" => signal_temp <= X"8000000080008008" ;                
    when others => signal_temp <=(others => '0');
    end case;
    end if;
end process;

    --0 регистр отвечает за режим
    -- process(S_AXI_ACLK)
    -- begin
    --      case slv_reg0 is
    --      when x"00000000" => r<=1088;
    --      when x"00000001" => r<=832;
    --      when x"00000002" => r<=832;
    --      when x"00000003" => r<=576;
    --      when others => r<=1088;
    --   end case;
    -- end process;

  s0:  for u in 0 to 1599 generate
          S_vector(u)<='0';
        end generate;
 
process (S_AXI_ACLK, start)
begin
     if start = '0' then
           cnt <= (others=>'0');
     elsif S_AXI_ACLK = '1' and S_AXI_ACLK'EVENT then
          cnt <= cnt + 1;
       end if;
end process;

        tick <= cnt(2);
        
        process (S_AXI_ACLK, start)
        begin
             if start = '0' then
                   tick1<='0';
             elsif S_AXI_ACLK = '1' and S_AXI_ACLK'EVENT then
                  tick1 <= tick;
               end if;
       end process;

i000:  for row in 0 to 4 generate
i001:    for col in 0 to 4 generate
i002:       for i in 0 to 63 generate
                A_array(row)(col)(i)<=S_vector1(64*(5*row+col)+i);
            end generate;
          end generate;
        end generate;


   slv_reg48(15 downto 0)<=x"0116";

   process (tick1,start)
   begin
    if (start='0' or first='0') then 
        counter_nr_rounds <= (others => '0');
    else
        if(tick1'event and tick1='1') then
            if (counter_nr_rounds < 23) then
              counter_nr_rounds <= counter_nr_rounds + 1;
            else 
              counter_nr_rounds <=counter_nr_rounds;                   
            end if;
        end if;
    end if;
   end process;
   

   process (tick1,start)
   begin
    if(start='0') then
        last<='0';
    else
        if(tick1'event and tick1='1') then
            if(first='1') then
                 if (counter_nr_rounds >= 23) then
                    last<='1';                   
                 end if;
            end if;
        end if;
    end if;
   end process;
   
  process (tick,start,first)
  begin
    if (start='0' or first='0') then
        round_in<=A_array;
    else
        if(tick'event and tick='1') then
             if (counter_nr_rounds < 23) then
                 round_in <= round_out;
             else 
                 for i in 0 to 31 loop
                    slv_reg40(i)<=round_out(0)(0)(i);
                    slv_reg41(i)<=round_out(0)(0)(32+i);
                    slv_reg42(i)<=round_out(0)(1)(i);
                    slv_reg43(i)<=round_out(0)(1)(32+i);
                    slv_reg44(i)<=round_out(0)(2)(i);
                    slv_reg45(i)<=round_out(0)(2)(32+i);
                    slv_reg46(i)<=round_out(0)(3)(i);
                    slv_reg47(i)<=round_out(0)(3)(32+i);              
                  end loop; 
             end if;
        end if;
    end if;
   end process;
      
   process (tick,start)
   begin
    if start='0' then
        first<='0';
    else
        if(tick'event and tick='0') then
            if(first='0')then 
                first<='1';
                end if;
            end if;
        end if;
   end process;
   
   process (S_AXI_ACLK)
   begin
    if(S_AXI_ACLK'event and S_AXI_ACLK='1') then
        if (start='1') then
                S_vector1(31 downto 0)      <=  S_vector(31 downto 0) xor slv_reg4;
                S_vector1(63 downto 32)     <=  S_vector(63 downto 32) xor slv_reg5;
                S_vector1(95 downto 64)     <=  S_vector(95 downto 64) xor slv_reg6;
                S_vector1(127 downto 96)    <=  S_vector(127 downto 96) xor slv_reg7;
                S_vector1(159 downto 128)   <=  S_vector(159 downto 128) xor slv_reg8;
                S_vector1(191 downto 160)   <=  S_vector(191 downto 160) xor slv_reg9;
                S_vector1(223 downto 192)   <=  S_vector(223 downto 192) xor slv_reg10;
                S_vector1(255 downto 224)   <=  S_vector(255 downto 224) xor slv_reg11;
                S_vector1(287 downto 256)   <=  S_vector(287 downto 256) xor slv_reg12;
                S_vector1(319 downto 288)   <=  S_vector(319 downto 288) xor slv_reg13;
                S_vector1(351 downto 320)   <=  S_vector(351 downto 320) xor slv_reg14;
                S_vector1(383 downto 352)   <=  S_vector(383 downto 352) xor slv_reg15;
                S_vector1(415 downto 384)   <=  S_vector(415 downto 384) xor slv_reg16;
                S_vector1(447 downto 416)   <=  S_vector(447 downto 416) xor slv_reg17;
                S_vector1(479 downto 448)   <=  S_vector(479 downto 448) xor slv_reg18;
                S_vector1(511 downto 480)   <=  S_vector(511 downto 480) xor slv_reg19;
                S_vector1(543 downto 512)   <=  S_vector(543 downto 512) xor slv_reg20;
                S_vector1(575 downto 544)   <=  S_vector(575 downto 544) xor slv_reg21;
                S_vector1(607 downto 576)   <=  S_vector(607 downto 576) xor slv_reg22;
                S_vector1(639 downto 608)   <=  S_vector(639 downto 608) xor slv_reg23;
                S_vector1(671 downto 640)   <=  S_vector(671 downto 640) xor slv_reg24;
                S_vector1(703 downto 672)   <=  S_vector(703 downto 672) xor slv_reg25;
                S_vector1(735 downto 704)   <=  S_vector(735 downto 704) xor slv_reg26;
                S_vector1(767 downto 736)   <=  S_vector(767 downto 736) xor slv_reg27;
                S_vector1(799 downto 768)   <=  S_vector(799 downto 768) xor slv_reg28;
                S_vector1(831 downto 800)   <=  S_vector(831 downto 800) xor slv_reg29;
                S_vector1(863 downto 832)   <=  S_vector(863 downto 832) xor slv_reg30;
                S_vector1(895 downto 864)   <=  S_vector(895 downto 864) xor slv_reg31;
                S_vector1(927 downto 896)   <=  S_vector(927 downto 896) xor slv_reg32;
                S_vector1(959 downto 928)   <=  S_vector(959 downto 928) xor slv_reg33;
                S_vector1(991 downto 960)   <=  S_vector(991 downto 960) xor slv_reg34;
                S_vector1(1023 downto 992)  <=  S_vector(1023 downto 992) xor slv_reg35;
                S_vector1(1055 downto 1024) <=  S_vector(1055 downto 1024) xor slv_reg36;
                S_vector1(1087 downto 1056) <=  S_vector(1087 downto 1056) xor slv_reg37;
                S_vector1(1119 downto 1088) <=  S_vector(1119 downto 1088) xor slv_reg38;
                S_vector1(1151 downto 1120) <=  S_vector(1151 downto 1120) xor slv_reg39;
                S_vector1(1599 downto 1152) <=  S_vector(1599 downto 1152);                   
            end if;
            end if;
   end process;
   
   slv_reg49(0)<=last;
    
	-- User logic ends

end arch_imp;
