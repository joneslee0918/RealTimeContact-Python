# Declare this file as a StarkNet contract and set the require builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math import assert_nn, assert_le, assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add, uint256_sub, uint256_mul, uint256_unsigned_div_rem,
    uint256_le, uint256_lt, uint256_check, uint256_eq
)

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.token.ERC1155.ERC1155_struct import TokenUri
from contracts.token.ERC1155.ERC1155_base import (
    # ERC1155_transfer_from,
    # ERC1155_batch_transfer_from,
    ERC1155_mint,
    # ERC1155_URI,
    # ERC1155_set_approval_for_all,
    # ERC1155_balances,
    # ERC1155_assert_is_owner_or_approved
)

#FIXME Non-reentrant

# Contract Address of ERC20 address for this swap contract
@storage_var
func currency_address() -> (address : felt):
end

# Contract Address of ERC1155 address for this swap contract
@storage_var
func token_address() -> (address : felt):
end

# Current reserves of currency
#FIXME Per token
@storage_var
func currency_reserves() -> (reserves : Uint256):
end

# Combined reserves of curreny
@storage_var
func currency_total() -> (total : Uint256):
end

# Total supplied currency
#FIXME Per token
@storage_var
func supplies_total() -> (total : Uint256):
end

@constructor
func constructor {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        currency_address_: felt,
        token_address_: felt,
    ):
        currency_address.write(currency_address_)
        token_address.write(token_address_)
    return ()
end

#
# Liquidity
#

@external
func add_liquidity {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        max_currency_amount: Uint256,
        token_id: felt,
        token_amount: felt,
    ):
        #FIXME add deadline
        alloc_locals
        let (caller) = get_caller_address() #FIXME method param
        let (contract) = get_contract_address()

        let (token_addr) = token_address.read()
        let (currency_addr) = currency_address.read()

        IERC20.transferFrom(currency_addr, caller, contract, max_currency_amount)
        tempvar syscall_ptr :felt* = syscall_ptr
        IERC1155.safeTransferFrom(token_addr, caller, contract, token_id, token_amount)

        #FIXME This is only for initial liquidity adds
        # Assert otherwise rounding error could end up being significant on second deposit
        # let (ok) = uint256_le(max_currency_amount, Uint256(0, 0))
        # assert_not_zero(ok)
        # let (ok) = uint256_le(Uint256(1000, 0), max_currency_amount)
        # assert_not_zero(ok)

        # Update currency  reserve size for Token id before transfer
        currency_reserves.write(max_currency_amount)

        # Update totalCurrency
        currency_total.write(max_currency_amount)

        # Initial liquidity is amount deposited (Incorrect pricing will be arbitraged)
        supplies_total.write(max_currency_amount)

        # Mint LP tokens
        ERC1155_mint(caller, token_id, max_currency_amount.low)

        #TODO emit LP Added Event

    return ()
end


#
# Swaps
#


@external
func buy_tokens {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        max_currency_amount: Uint256,
        token_id: felt,
        token_amount: felt,
    ) -> (
        sold: Uint256
    ):
    #FIXME Add deadline
    #FIXME Recipient as a param
    alloc_locals
    let (caller) = get_caller_address()
    let (contract) = get_contract_address()

    let (token_addr) = token_address.read()
    let (currency_addr) = currency_address.read()
    
    let (currency_res) = currency_reserves.read()
    let (token_reserves) = IERC1155.balanceOf(token_addr, contract, token_id)

    # Transfer max currency
    IERC20.transferFrom(currency_addr, caller, contract, max_currency_amount)
    tempvar syscall_ptr :felt* = syscall_ptr

    #FIXME Fees / royalties

    # Calculate prices
    let (currency_amount) = get_buy_price(Uint256(token_amount, 0), currency_res, Uint256(token_reserves, 0))

    #TODO Fees

    # Calculate refund
    let (refund_amount) = uint256_sub(max_currency_amount, currency_amount)

    # Update reserves
    let (new_reserves, _) = uint256_add(currency_res, currency_amount)

    # Transfer refunded currency and purchased tokens
    IERC20.transfer(currency_addr, caller, refund_amount)
    tempvar syscall_ptr :felt* = syscall_ptr
    IERC1155.safeTransferFrom(token_addr, contract, caller, token_id, token_amount)

    return (currency_amount)
end



@view
func get_buy_price {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token_amount: Uint256,
        currency_reserves: Uint256,
        token_reserves: Uint256,
    ) -> (
        price: Uint256
    ):
    alloc_locals

    # Calculate price
    #FIXME Add fee
    let (numerator, _) = uint256_mul(currency_reserves, token_amount)
    # let (numerator, _) = uint256_mul(numerator, Uint256(1000, 0)) TODO Why is this here
    let (token_res_left) = uint256_sub(token_reserves, token_amount)
    let (price, remainder) = uint256_unsigned_div_rem(numerator, token_res_left)
    #FIXME If remainder then add 1
    # let (is_not_z) = uint256_eq(remainder, Uint256(0, 0))
    # if is_not_z == (1):
    #     let (price, _) = uint256_add(price, Uint256(1, 0))
    # end

    return (price)

end

#
# Getters
#

@view
func get_currency_address {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (currency_address: felt):
    return currency_address.read()
end

@view
func get_token_address {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (token_address: felt):
    return token_address.read()
end





# #
# # Exchange is ERC1155 compliant as LP tokens are ERC1155
# #

# @external
# func SetURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(uri_ : TokenUri):
#     ERC1155_URI.write(uri_)
#     return ()
# end

# @external
# func setApprovalForAll{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
#         operator : felt, approved : felt):
#     let (account) = get_caller_address()
#     ERC1155_set_approval_for_all(operator, approved)
#     return ()
# end

# @external
# func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
#         sender : felt, recipient : felt, token_id : felt, amount : felt):
#     ERC1155_assert_is_owner_or_approved(sender)
#     ERC1155_transfer_from(sender, recipient, token_id, amount)
#     return ()
# end

# @external
# func safeBatchTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
#         sender : felt, recipient : felt, tokens_id_len : felt, tokens_id : felt*,
#         amounts_len : felt, amounts : felt*):
#     ERC1155_assert_is_owner_or_approved(sender)
#     ERC1155_batch_transfer_from(sender, recipient, tokens_id_len, tokens_id, amounts_len, amounts)
#     return ()
# end
