//! SPDX-License-Identifier: MIT
//!
//! Base configuration for appchain contract.

/// Errors.
mod errors {
    pub const INVALID_CALLER: felt252 = 'Config: not owner or operator';
    pub const ALREADY_REGISTERED: felt252 = 'Config: already operator';
    pub const NOT_OPERATOR: felt252 = 'Config: not operator';
}

/// Configuration component.
///
/// Depends on `ownable` to ensure the configuration is
/// only editable by contract's owner.
#[starknet::component]
pub mod config_cpt {
    use openzeppelin::access::ownable::{
        OwnableComponent as ownable_cpt, OwnableComponent::InternalTrait as OwnableInternal,
        interface::IOwnable,
    };
    use piltover::config::interface::{IConfig, ProgramInfo};
    use starknet::ContractAddress;
    use starknet::storage::Map;
    use starknet::storage::{
        StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use super::errors;

    #[storage]
    pub struct Storage {
        /// Appchain operators that are allowed to update the state.
        pub operators: Map<ContractAddress, bool>,
        /// The information of the program verified to apply the state transition.
        pub program_info: ProgramInfo,
        /// Facts registry contract address.
        pub facts_registry: ContractAddress,
    }

    #[event]
    #[derive(Copy, Drop, starknet::Event)]
    pub enum Event {
        ProgramInfoChanged: ProgramInfoChanged,
    }

    #[derive(Copy, Drop, starknet::Event)]
    struct ProgramInfoChanged {
        changed_by: ContractAddress,
        old_program_info: ProgramInfo,
        new_program_info: ProgramInfo,
    }

    #[embeddable_as(ConfigImpl)]
    impl Config<
        TContractState,
        +HasComponent<TContractState>,
        impl Ownable: ownable_cpt::HasComponent<TContractState>,
    > of IConfig<ComponentState<TContractState>> {
        fn register_operator(ref self: ComponentState<TContractState>, address: ContractAddress) {
            get_dep_component!(@self, Ownable).assert_only_owner();
            assert(!self.operators.read(address), errors::ALREADY_REGISTERED);
            self.operators.write(address, true);
        }

        fn unregister_operator(ref self: ComponentState<TContractState>, address: ContractAddress) {
            get_dep_component!(@self, Ownable).assert_only_owner();
            assert(self.operators.read(address), errors::NOT_OPERATOR);
            self.operators.write(address, false);
        }

        fn is_operator(self: @ComponentState<TContractState>, address: ContractAddress) -> bool {
            self.operators.read(address)
        }

        fn set_program_info(ref self: ComponentState<TContractState>, program_info: ProgramInfo) {
            self.assert_only_owner_or_operator();
            let old_program_info = self.program_info.read();
            self.program_info.write(program_info);
            self
                .emit(
                    ProgramInfoChanged {
                        changed_by: starknet::get_caller_address(),
                        old_program_info,
                        new_program_info: program_info,
                    },
                );
        }

        fn get_program_info(self: @ComponentState<TContractState>) -> ProgramInfo {
            self.program_info.read()
        }

        fn set_facts_registry(ref self: ComponentState<TContractState>, address: ContractAddress) {
            self.assert_only_owner_or_operator();
            self.facts_registry.write(address)
        }

        fn get_facts_registry(self: @ComponentState<TContractState>) -> ContractAddress {
            self.facts_registry.read()
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl Ownable: ownable_cpt::HasComponent<TContractState>,
    > of InternalTrait<TContractState> {
        /// Asserts if the caller is the owner of the contract or
        /// the authorized operator. Reverts otherwise.
        fn assert_only_owner_or_operator(ref self: ComponentState<TContractState>) {
            assert(
                self.is_owner_or_operator(starknet::get_caller_address()), errors::INVALID_CALLER,
            );
        }

        /// Verifies if the given address is the owner of the contract
        /// or the authorized operator.
        ///
        /// # Arguments
        ///
        /// * `address` - The contrat address to verify.
        fn is_owner_or_operator(
            ref self: ComponentState<TContractState>, address: ContractAddress,
        ) -> bool {
            let owner = get_dep_component!(@self, Ownable).owner();
            address == owner || self.is_operator(address)
        }
    }
}
