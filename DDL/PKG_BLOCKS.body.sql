CREATE OR REPLACE PACKAGE BODY BTC_USER.PKG_BLOCKS
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
return number
is
l_block_header_ref number:= s_block_headers.nextval;
begin
	insert into block_headers(
				BLOCK_HEADER_REF,
				WRITE_TIMESTAMP,
				VERSION,
				PREV_HASH,
				MERKLE_TREE_ROOT,
				TIME,
				BITS,
				NONCE,
				TX_COUNT,
				BLOCK_HASH,
				BLOCK_HEIGHT
		) values (
				l_block_header_ref,
				systimestamp,
				p_version,
				p_prev_hash,
				p_merkle_tree_root,
				p_time,
				p_bits,
				p_nonce,
				p_tx_count,
				p_block_hash,
				p_block_height
		);
	return l_block_header_ref;
end;

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
return number
is
l_block_transaction_ref number := s_block_transactions.nextval;
begin
	insert into block_transactions(
				BLOCK_TRANSACTION_REF,
				BLOCK_HEADER_REF,
				TX_HASH,
				TX_VERSION,
				TX_IN_COUNT,
				TX_OUT_COUNT,
				TX_LOCK_TIME,
				TX_LOCK_TIMESTAMP,
				TX_COINBASE_FLAG
		) values (
				l_block_transaction_ref,
				p_block_header_ref,
				p_tx_hash,
				p_tx_version,
				p_tx_in_count,
				p_tx_out_count,
				p_tx_lock_time,
				p_tx_lock_timestamp,
				p_tx_coinbase_flag
		);
	return l_block_transaction_ref;
end;

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
return number
is
l_transaction_input_ref number := s_transaction_inputs.nextval;
l_amount number;
begin
	select max(amount) into l_amount from utxo where tx_hash = p_prev_out_hash and output_index = p_prev_out_index;

	insert into transaction_inputs(
				TRANSACTION_INPUT_REF,
				BLOCK_TRANSACTION_REF,
				INPUT_INDEX,
				PREV_OUT_HASH,
				PREV_OUT_INDEX,
				SIG_SCRIPT_SIZE,
				SIG_SCRIPT,
				SIG_SCRIPT_ASM,
				SEQUENCE,
				AMOUNT
		) values (
				l_transaction_input_ref,
				p_block_transaction_ref,
				p_input_index,
				p_prev_out_hash,
				p_prev_out_index,
				p_sig_script_size,
				p_sig_script,
				p_sig_script_asm,
				p_sequence,
				l_amount
		);
	update utxo set spent_flag = 'Y' where tx_hash = p_prev_out_hash and output_index = p_prev_out_index;
	return l_transaction_input_ref;
end;


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
return number
is
l_transaction_output_ref  number := s_transaction_outputs.nextval;
begin
	insert into transaction_outputs(
				TRANSACTION_OUTPUT_REF,
				BLOCK_TRANSACTION_REF,
				TX_HASH,
				OUTPUT_INDEX,
				AMOUNT,
				PK_SCRIPT_SIZE,
				PK_SCRIPT,
				PK_SCRIPT_ASM,
				PK_SCRIPT_TYPE
		) values (
				l_transaction_output_ref,
				p_block_transaction_ref,
				p_tx_hash,
				p_output_index,
				p_amount,
				p_pk_script_size,
				p_pk_script,
				p_pk_script_asm,
				p_pk_script_type
		);

	insert into utxo(
				UTXO_REF,
				TRANSACTION_OUTPUT_REF,
				TX_HASH,
				OUTPUT_INDEX,
				AMOUNT,
				PK_SCRIPT_SIZE,
				PK_SCRIPT,
				PK_SCRIPT_ASM,
				PK_SCRIPT_TYPE,
				SPENT_FLAG
		) values (
				s_utxo.nextval,
				l_transaction_output_ref,
				p_tx_hash,
				p_output_index,
				p_amount,
				p_pk_script_size,
				p_pk_script,
				p_pk_script_asm,
				p_pk_script_type,
				'N'
		);

	return l_transaction_output_ref;
	
end;

--===================================================================
function f_ins_output_address( 
				p_transaction_output_ref   number,
				p_tx_hash   varchar2,
				p_output_index   number,
				p_address_index   number,
				p_public_key varchar2,
				p_address varchar2,
				p_address_type varchar2
)
return number
is
l_output_address_ref number := s_output_addresses.nextval;
begin
	insert into output_addresses (
				OUTPUT_ADDRESS_REF,
				TRANSACTION_OUTPUT_REF,
				ADDRESS_INDEX,
				PUBLIC_KEY,
				ADDRESS,
				ADDRESS_TYPE
		) values (
				l_output_address_ref,
				p_transaction_output_ref,
				p_address_index,
				p_public_key,
				p_address,
				p_address_type);

	insert into utxo_addresses (
				TX_HASH,
				OUTPUT_INDEX,
				ADDRESS_INDEX,
				PUBLIC_KEY,
				ADDRESS,
				ADDRESS_TYPE
		) values (
				p_tx_hash,
				p_output_index,
				p_address_index,
				p_public_key,
				p_address,
				p_address_type);
	
	return l_output_address_ref;
end;

--===================================================================
procedure sp_post_process_transaction(p_block_transaction_ref number)
is
begin
	update block_transactions set fee = (select sum(amount) from transaction_inputs where block_transaction_ref = p_block_transaction_ref) - (select sum(amount) from transaction_outputs where block_transaction_ref = p_block_transaction_ref) where block_transaction_ref = p_block_transaction_ref;
end;

--===================================================================
procedure sp_post_process_block(p_block_header_ref number)
is
begin
	null;
	--update block_transactions set fee = (select sum(amount) from transaction_inputs where block_transaction_ref = p_block_transaction_ref) - (select sum(amount) from transaction_outputs where block_transaction_ref = p_block_transaction_ref) where block_transaction_ref = p_block_transaction_ref;
end;

END PKG_BLOCKS;
/
