CREATE TABLE BTC_USER.TRANSACTION_OUTPUTS
(
    TRANSACTION_OUTPUT_REF NUMBER       NOT NULL,
    BLOCK_TRANSACTION_REF  NUMBER       NOT NULL,
    TX_HASH                VARCHAR2(64) NOT NULL,
    OUTPUT_INDEX           NUMBER(10,0) NOT NULL,
    AMOUNT                 NUMBER(38,0) NOT NULL,
    PK_SCRIPT_SIZE         NUMBER       NOT NULL,
    PK_SCRIPT              CLOB         NOT NULL,
    PK_SCRIPT_ASM          CLOB         NOT NULL,
    PK_SCRIPT_TYPE         VARCHAR2(20)     NULL
)
ORGANIZATION HEAP
LOB(PK_SCRIPT) STORE AS SECUREFILE 
(
    TABLESPACE USERS
    STORAGE(INITIAL 104K)
    ENABLE STORAGE IN ROW
    NOCACHE
    LOGGING
    CHUNK 8192
)
LOB(PK_SCRIPT_ASM) STORE AS SECUREFILE 
(
    TABLESPACE USERS
    STORAGE(INITIAL 104K)
    ENABLE STORAGE IN ROW
    NOCACHE
    LOGGING
    CHUNK 8192
)
TABLESPACE USERS
LOGGING
PCTFREE 10
PCTUSED 0
INITRANS 1
MAXTRANS 255
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
NOROWDEPENDENCIES
/
ALTER TABLE BTC_USER.TRANSACTION_OUTPUTS
    ADD CONSTRAINT TRANSACTION_OUTPUTS_PK
    PRIMARY KEY (TRANSACTION_OUTPUT_REF)
    USING INDEX TABLESPACE USERS
                PCTFREE 10
                INITRANS 2
                MAXTRANS 255
                STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
/
ALTER TABLE BTC_USER.OUTPUT_ADDRESSES
    ADD CONSTRAINT OUTPUT_ADDRESSES_FK1
    FOREIGN KEY (TRANSACTION_OUTPUT_REF)
    REFERENCES BTC_USER.TRANSACTION_OUTPUTS (TRANSACTION_OUTPUT_REF)
    ON DELETE CASCADE
    ENABLE
    VALIDATE
/
ALTER TABLE BTC_USER.UTXO
    ADD CONSTRAINT UTXO_FK1
    FOREIGN KEY (TRANSACTION_OUTPUT_REF)
    REFERENCES BTC_USER.TRANSACTION_OUTPUTS (TRANSACTION_OUTPUT_REF)
    ON DELETE CASCADE
    ENABLE
    VALIDATE
/
ALTER TABLE BTC_USER.TRANSACTION_OUTPUTS
    ADD CONSTRAINT TRANSACTION_OUTPUT_FK1
    FOREIGN KEY (BLOCK_TRANSACTION_REF)
    REFERENCES BTC_USER.BLOCK_TRANSACTIONS (BLOCK_TRANSACTION_REF)
    ON DELETE CASCADE
    ENABLE
    VALIDATE
/
