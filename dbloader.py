import json
import cx_Oracle
import urllib.request
import time

from binascii import a2b_hex, b2a_hex
from datetime import datetime
from blockchain_parser.block import Block

# filename = 'c:\\medium.00000000000000000159565038ba1aec4bb9cc245f43fa3c2eed7ab0154ca40e.txt'
# txtFile = open(filename, 'r')
#
#
# i = 0
# # Iterate through each make in text file
# for line in txtFile:
#     rawText = line.strip()
#     i = i + 1
# txtFile.close()


class DBLoader(object):
    def __init__(self, rawHex):
        self.raw_ex = rawHex

    @classmethod
    def from_hex(cls, hex_):
        return cls(hex_)

    @classmethod
    def load(cls):
        #print(len(rawHex))

        block = Block.from_hex(rawHex)

        # print(block.header.version)
        # print(block.header.previous_block_hash)
        # print(block.header.merkle_root)
        # print(block.header.nonce)
        # print(block.header.bits)
        # print(block.header.difficulty)
        print(block.header.timestamp)
        print(block.hash)
        print(block.height)


        con = cx_Oracle.connect('btc_user', 'btc_user', 'localhost/plug_mydev',
                     cclass = "HOL", purity = cx_Oracle.ATTR_PURITY_SELF)

        # function f_ins_block_header(
        # 				p_version   number,
        # 				p_prev_hash   varchar2,
        # 				p_merkle_tree_root   varchar2,
        # 				p_time   timestamp,
        # 				p_bits   number,
        # 				p_nonce   number,
        # 				p_tx_count   number,
        # 				p_block_hash   varchar2,
        # 				p_block_height   number

        cur = con.cursor()
        clob1 = cur.var(cx_Oracle.CLOB)
        clob2 = cur.var(cx_Oracle.CLOB)

        block_header_ref = cur.callfunc('pkg_blocks.f_ins_block_header', cx_Oracle.NUMBER,( \
                            block.header.version, \
                            block.header.previous_block_hash, \
                            block.header.merkle_root, \
                            block.header.timestamp, \
                            block.header.bits, \
                            block.header.nonce, \
                            block.n_transactions, \
                            block.hash, \
                            block.height))

        # function f_ins_BLOCK_TRANSACTION(
        # 				p_block_header_ref   number,
        # 				p_tx_hash   varchar2,
        # 				p_tx_version   number,
        # 				p_tx_in_count   number,
        # 				p_tx_out_count   number,
        # 				p_tx_lock_time   number,
        # 				p_tx_lock_timestamp   timestamp,
        # 				p_tx_coinbase_flag   char
        # )
        for tx in block.transactions:
            block_transaction_ref = cur.callfunc('pkg_blocks.f_ins_block_transaction', cx_Oracle.NUMBER,( \
                            block_header_ref, \
                            tx.hash, \
                            tx.version, \
                            tx.n_inputs, \
                            tx.n_outputs, \
                            tx.locktime, \
                            datetime.utcfromtimestamp(tx.locktime) if tx.locktime > 500000000 else None, \
                            "Y" if tx.is_coinbase() else "N"))

        # function f_ins_TRANSACTION_INPUT(
        # 				p_block_transaction_ref   number,
        # 				p_input_index   number,
        # 				p_prev_out_hash   varchar2,
        # 				p_prev_out_index   number,
        # 				p_sig_script_size   number,
        # 				p_sig_script   clob,
        # 				p_sequence   number
        # )
        # return number
            i = 0
            for inp in tx.inputs:
                clob1.setvalue(0, b2a_hex(inp.script.hex).decode('utf8'))
                clob2.setvalue(0, inp.script.value)
                transaction_input_ref = cur.callfunc('pkg_blocks.f_ins_transaction_input', cx_Oracle.NUMBER,( \
                            block_transaction_ref, \
                            i, \
                            inp.transaction_hash, \
                            inp.transaction_index, \
                            inp._script_length, \
                            # b2a_hex(inp.script.hex).decode('utf8'), \
                            # inp.script.value, \
                            clob1, \
                            clob2, \
                            inp.sequence_number))
                i += 1

        # function f_ins_TRANSACTION_OUTPUT(
        # 				p_block_transaction_ref   number,
        # 				p_tx_hash   varchar2,
        # 				p_output_index   number,
        # 				p_amount   number,
        # 				p_pk_script_size   number,
        # 				p_pk_script   clob,
        # 				p_pk_script_type varchar2
        #
        # )

            i = 0
            for outp in tx.outputs:
                clob1.setvalue(0, b2a_hex(outp.script.hex).decode('utf8'))
                clob2.setvalue(0, outp.script.value)
                transaction_output_ref = cur.callfunc('pkg_blocks.f_ins_transaction_output', cx_Oracle.NUMBER,( \
                            block_transaction_ref, \
                            tx.hash, \
                            i, \
                            outp.value, \
                            outp._script_length, \
                            # b2a_hex(outp.script.hex).decode('utf8'), \
                            # outp.script.value, \
                            clob1, \
                            clob2, \
                            outp.type))

        # function f_ins_output_address(
        # 				p_transaction_output_ref   number,
        # 				p_address_index   number,
        # 				p_public_key varchar2,
        # 				p_address varchar2,
        # 				p_address_type varchar2
        # )

                j = 0
                for addr in outp.addresses:
                    output_address_ref = cur.callfunc('pkg_blocks.f_ins_output_address', cx_Oracle.NUMBER,( \
                            transaction_output_ref, \
                            tx.hash, \
                            i, \
                            j, \
                            addr.public_key, \
                            addr.address, \
                            addr.type))
                    j += 1

                i += 1
            if not tx.is_coinbase():
                cur.callproc('pkg_blocks.sp_post_process_transaction', [block_transaction_ref])

        con.commit()
        cur.close()
        con.close()

        #
        #     print(tx.version)
        #     print(tx.hash)
        #     print(tx.size)
        #     for inp in tx.inputs:
        #         print(inp.transaction_hash)
        #         print(inp.transaction_index)


for jj in range(71037,100000):
    print(jj)
    ok = False
    while not ok:
        try:
            url = 'https://blockchain.info/block-height/' + str(jj) + '?format=json'
            blk = urllib.request.urlopen(url).read().decode("utf-8")
            data = json.loads(blk)

            hs = data["blocks"][0]["hash"]

            rawText = urllib.request.urlopen("https://blockchain.info/rawblock/" + hs + "?format=hex").read()
            ok = True
        except Exception as e:
            print(e.args)
            ok = False
            time.sleep(10)


    rawHex = a2b_hex(rawText)
    db = DBLoader.from_hex(rawHex)
    db.load()
