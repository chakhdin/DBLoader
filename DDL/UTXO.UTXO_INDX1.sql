DROP INDEX BTC_USER.UTXO_INDX1
/
CREATE UNIQUE INDEX BTC_USER.UTXO_INDX1
    ON BTC_USER.UTXO(TX_HASH,OUTPUT_INDEX)
TABLESPACE USERS
LOGGING
PCTFREE 10
INITRANS 2
MAXTRANS 255
STORAGE(INITIAL 64K
        BUFFER_POOL DEFAULT)
NOPARALLEL
NOCOMPRESS
/
