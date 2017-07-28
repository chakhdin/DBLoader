import urllib.request
from binascii import a2b_hex, b2a_hex
from datetime import datetime
import cx_Oracle

from blockchain_parser.block import Block

filename = 'c:\\medium.00000000000000000159565038ba1aec4bb9cc245f43fa3c2eed7ab0154ca40e.txt'
#filename = 'c:\\new.000000000000000001545df793cd8194f878c0261b132dc6c71df3044a40de56.txt'
# Open text file for reading
txtFile = open(filename, 'r')


i = 0
# Iterate through each make in text file
for line in txtFile:
    rawText = line.strip()
    i = i + 1
txtFile.close()

rawText = urllib.request.urlopen("https://blockchain.info/rawblock/0000000000000000013fe2cd0ccc7a0c4b5f08b1dc0a24265624a364545ef5fe?format=hex").read()

rawHex = a2b_hex(rawText)

print(len(rawHex))

block = Block.from_hex(rawHex)
print(block.header.version)
print(block.header.previous_block_hash)
print(block.header.merkle_root)
print(block.header.nonce)
print(block.header.bits)
print(block.header.difficulty)
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
        transaction_input_ref = cur.callfunc('pkg_blocks.f_ins_transaction_input', cx_Oracle.NUMBER,( \
                    block_transaction_ref, \
                    i, \
                    inp.transaction_hash, \
                    inp.transaction_index, \
                    inp._script_length, \
                    b2a_hex(inp.script.hex).decode('utf8'), \
                    inp.script.value, \
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
        transaction_output_ref = cur.callfunc('pkg_blocks.f_ins_transaction_output', cx_Oracle.NUMBER,( \
                    block_transaction_ref, \
                    tx.hash, \
                    i, \
                    outp.value, \
                    outp._script_length, \
                    b2a_hex(outp.script.hex).decode('utf8'), \
                    outp.script.value, \
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
                    j,
                    addr.public_key, \
                    addr.address, \
                    addr.type))
            j += 1

        i += 1

con.commit()
print(block_header_ref)
cur.close()
con.close()

#
#     print(tx.version)
#     print(tx.hash)
#     print(tx.size)
#     for inp in tx.inputs:
#         print(inp.transaction_hash)
#         print(inp.transaction_index)
