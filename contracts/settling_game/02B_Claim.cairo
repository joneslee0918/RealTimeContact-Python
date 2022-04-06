%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import scale
from contracts.settling_game.utils.interfaces import IModuleController

from contracts.settling_game.utils.game_structs import ResourceLevel 

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.settling_game.realms_IERC721 import realms_IERC721

# #### Module 2B #####
# Claim & Resource State
####################

# ########### Game state ############

# Stores the address of the ModuleController.
@storage_var
func controller_address() -> (address : felt):
end

@storage_var
func resource_levels(token_id: Uint256, resource_id: felt) -> (level : felt):
end

# ########### Admin Functions for Testing ############
# Called on deployment only.
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    # Store the address of the only fixed contract in the system.
    controller_address.write(address_of_controller)
    return ()
end

@external 
func get_resource_level{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_id : Uint256, resource : felt) -> (level: felt):
    alloc_locals

    local l

    let (level) = resource_levels.read(token_id, resource)

    if level == 0: 
        assert l = 10
    else:
        assert l = level    
    end    

    return (level=l)  
end


# Checks write-permission of the calling contract.
func only_approved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # Get the address of the module trying to write to this contract.
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()
    # Pass this address on to the ModuleController.
    # "Does this address have write-authority here?"
    # Will revert the transaction if not.
    IModuleController.has_write_access(
        contract_address=controller, address_attempting_to_write=caller)
    return ()
end
