[ SYSTEM BUS ]
            |
            | Configuration (Control, Pointers, Security Bounds)
            v
 _________________________________________________________________________
|                                                                         |
|  HOST INTERFACE & CONFIGURATION REGISTERS                               |
|  [OFF_CONTROL] [OFF_SRC_ADDR] [OFF_DST_ADDR] [OFF_2D_STRIDE]            |
|  [OFF_SRC_BOUND] [OFF_DST_BOUND] <--- DP-3 Hardware Security Limits     |
|_________________________________________________________________________|
            |                               |
            | [Current Pointers]            | [Static Limits]
            v                               v
 __________________________        _______________________________________
|                          |      |                                       |
|  ADDRESS GENERATOR (AGU) |      |    HARDWARE MPU (SECURITY GUARD)      |
|  * 2D-Striding Logic     |----->|    * Source Comparator (addr > bound) |
|  * Stride Offset Adder   |      |    * Dest Comparator (addr > bound)   |
|__________________________|      |_______________________________________|
            |                               |
            | [Next Address]                | [addr_fault] (Kill Signal)
            |                               v
            |             ________________________________________________
            |            |                                                |
            |            |           FINITE STATE MACHINE (FSM)           |
            |            |  [IDLE] -> [FETCH] -> [WRITE] -> [DONE/ERROR]  |
            |            |________________________________________________|
            |                    |                  |
            |                    | [Abort Control]  | [Set Status Bits]
            v                    v                  v
 _________________________________________        ________________________
|                                         |      |                        |
|        MASTER BUS INTERFACE             |      |    STATUS REGISTER     |
|  (m_addr, m_wdata, m_valid, m_ready)    |      |  [sec_violation] (bit 3) |
|_________________________________________|      |  [err_flag]      (bit 2) |
            ^                    ^               |________________________|
            |                    |                          |
     [DATA PIPELINE]      [BYTE STROBE LOGIC]      [USER INTERRUPT PIN]
      (Verified Path)      (Alignment Logic)          (Active High)