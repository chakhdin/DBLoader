CREATE TABLE BTC_USER.TRANSACTION_INPUTS
(
    TRANSACTION_INPUT_REF NUMBER       NOT NULL,
    BLOCK_TRANSACTION_REF NUMBER       NOT NULL,
    INPUT_INDEX           NUMBER(10,0) NOT NULL,
    PREV_OUT_HASH         VARCHAR2(64) NOT NULL,
    PREV_OUT_INDEX        NUMBER(10,0) NOT NULL,
    SIG_SCRIPT_SIZE       NUMBER       NOT NULL,
    SIG_SCRIPT            CLOB         NOT NULL,
    SIG_SCRIPT_ASM        CLOB         NOT NULL,
    SEQUENCE              NUMBER(10,0) NOT NULL
)
ORGANIZATION HEAP
LOB(SIG_SCRIPT) STORE AS SECUREFILE 
(
    TABLESPACE USERS
    STORAGE(INITIAL 104K)
    ENABLE STORAGE IN ROW
    NOCACHE
    LOGGING
    CHUNK 8192
)
LOB(SIG_SCRIPT_ASM) STORE AS SECUREFILE 
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
ALTER TABLE BTC_USER.TRANSACTION_INPUTS
    ADD CONSTRAINT TRANSACTION_INPUTS_PK
    PRIMARY KEY (TRANSACTION_INPUT_REF)
    USING INDEX TABLESPACE USERS
                PCTFREE 10
                INITRANS 2
                MAXTRANS 255
                STORAGE(BUFFER_POOL DEFAULT)
    LOGGING
    ENABLE
    VALIDATE
/
ALTER TABLE BTC_USER.TRANSACTION_INPUTS
    ADD CONSTRAINT TRANSACTION_INPUT_FK1
    FOREIGN KEY (BLOCK_TRANSACTION_REF)
    REFERENCES BTC_USER.BLOCK_TRANSACTIONS (BLOCK_TRANSACTION_REF)
    ON DELETE CASCADE
    ENABLE
    VALIDATE
/