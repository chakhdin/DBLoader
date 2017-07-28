CREATE OR REPLACE PACKAGE BTC_USER.PKG_BLOCKS
as

--===================================================================
function f_ins_block_header( 
				p_version   number,
				p_prev_hash   varchar2,
				p_merkle_tree_root   varchar2,
				p_time   timestamp,
				p_bits   number,
				p_nonce   number,
				p_tx_count   number,
				p_block_hash   varchar2,
				p_block_height   number
)
return number;

--===================================================================
function f_ins_block_transaction( 
				p_block_header_ref   number,
				p_tx_hash   varchar2,
				p_tx_version   number,
				p_tx_in_count   number,
				p_tx_out_count   number,
				p_tx_lock_time   number,
				p_tx_lock_timestamp   timestamp,
				p_tx_coinbase_flag   char
)
return number;

--===================================================================
function f_ins_transaction_input( 
				p_block_transaction_ref   number,
				p_input_index   number,
				p_prev_out_hash   varchar2,
				p_prev_out_index   number,
				p_sig_script_size   number,
				p_sig_script   clob,
				p_sig_script_asm   clob,
				p_sequence   number
)
return number;

--===================================================================
function f_ins_transaction_output( 
				p_block_transaction_ref   number,
				p_tx_hash   varchar2,
				p_output_index   number,
				p_amount   number,
				p_pk_script_size   number,
				p_pk_script   clob,
				p_pk_script_asm   clob,
				p_pk_script_type varchar2
)
return number;

--===================================================================
function f_ins_output_address( 
				p_transaction_output_ref   number,
				p_address_index   number,
				p_public_key varchar2,
				p_address varchar2,
				p_address_type varchar2
)
return number;

END PKG_BLOCKS;
/
