//! SPDX-License-Identifier: MIT
//!
//! Appchain - Starknet state component.

/// Errors.
mod errors {
    pub const INVALID_BLOCK_NUMBER: felt252 = 'State: invalid block number';
    pub const INVALID_PREVIOUS_ROOT: felt252 = 'State: invalid previous root';
    pub const INVALID_PREVIOUS_BLOCK_NUMBER: felt252 = 'State: invalid prev block num';
}

/// State component.
#[starknet::component]
pub mod state_cpt {
    use piltover::snos_output::StarknetOsOutput;
    use piltover::state::interface::IState;
    use starknet::storage::{
        MutableVecTrait, StorableStoragePointerReadAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess, Vec, VecTrait,
    };
    // use starknet::storage::*;
    use super::errors;

    type StateRoot = felt252;
    type BlockNumber = felt252;
    type BlockHash = felt252;

    #[storage]
    pub struct Storage {
        pub state_root: StateRoot,
        pub block_number: BlockNumber,
        pub block_hash: BlockHash,
        pub snos_output: Vec<felt252>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {}

    #[embeddable_as(StateImpl)]
    impl State<
        TContractState, +HasComponent<TContractState>,
    > of IState<ComponentState<TContractState>> {
        fn update(ref self: ComponentState<TContractState>, program_output: StarknetOsOutput) {
            assert(
                self.block_number.read() == program_output.prev_block_number,
                errors::INVALID_BLOCK_NUMBER,
            );

            self.block_number.write(program_output.new_block_number);
            self.block_hash.write(program_output.new_block_hash);

            assert(
                self.state_root.read() == program_output.initial_root,
                errors::INVALID_PREVIOUS_ROOT,
            );

            self.state_root.write(program_output.final_root);
        }

        fn get_state(self: @ComponentState<TContractState>) -> (StateRoot, BlockNumber, BlockHash) {
            (self.state_root.read(), self.block_number.read(), self.block_hash.read())
        }

        fn store_snos_output(
            ref self: ComponentState<TContractState>, _snos_output: Span<felt252>, from_index: u64,
        ) {
            assert(from_index <= self.snos_output.len(), 'invalid from index');

            let mut input_array_length: u64 = _snos_output.len().into();
            let current_len = self.snos_output.len();

            for i in 0..input_array_length {
            
                let current_index = i + from_index;
                if current_index < current_len {
                    let storage_pointer = self.snos_output.at(current_index);
                    storage_pointer.write(*_snos_output[i.try_into().unwrap()]);
                } else {
                    let x = self.snos_output.append();
                    x.write(*_snos_output[i.try_into().unwrap()]);
                }
            };
        }

        fn get_snos_output(
            self: @ComponentState<TContractState>, till_index: u64,
        ) -> Array<felt252> {
            let mut output = array![];
            for i in 0..till_index + 1 {
                let value = self.snos_output.at(i).read();
                output.append(value);
            };
            output
        }

        fn getLength_of_snop(self: @ComponentState<TContractState>) -> u64 {
            self.snos_output.len()
        }
    }


    #[generate_trait]
    pub impl InternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of InternalTrait<TContractState> {
        /// Initialized the messaging component.
        /// # Arguments
        ///
        /// * `state_root` - The state root.
        /// * `block_number` - The current block number.
        /// * `block_hash` - The hash of the current block.
        fn initialize(
            ref self: ComponentState<TContractState>,
            state_root: StateRoot,
            block_number: BlockNumber,
            block_hash: BlockHash,
        ) {
            self.state_root.write(state_root);
            self.block_number.write(block_number);
            self.block_hash.write(block_hash);
        }
    }
}
