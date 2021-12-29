import pytest
import asyncio

from fixtures.account import account_factory
from utils.string import str_to_felt

def uint(a):
    return(a, 0)


NUM_SIGNING_ACCOUNTS = 2


@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_game_creation(game_factory):

    _, accounts, signers, _, _, tower_defence, tower_defence_storage = game_factory

    admin_key = signers[0]
    admin_account = accounts[0]

    await admin_key.send_transaction(
        account=admin_account,
        to=tower_defence.contract_address,
        selector_name='create_game',
        calldata=[]
    )

    execution_info = await tower_defence_storage.get_latest_game_index().call()
    assert execution_info.result == (1,)

@pytest.fixture(scope='module')
async def game_factory(account_factory):
    (starknet, accounts, signers) = account_factory
    admin_key = signers[0]
    admin_account = accounts[0]

    # The Controller is the only unchangeable contract.
    # First deploy Arbiter.
    # Then send the Arbiter address during Controller deployment.
    # Then save the controller address in the Arbiter.
    # Then deploy Controller address during module deployments.
    arbiter = await starknet.deploy(
        source="contracts/l2/settling_game/Arbiter.cairo",
        constructor_calldata=[admin_account.contract_address])
    controller = await starknet.deploy(
        source="contracts/l2/settling_game/ModuleController.cairo",
        constructor_calldata=[arbiter.contract_address])
    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='set_address_of_controller',
        calldata=[controller.contract_address])
    print(admin_account)
    attack_token = await starknet.deploy(
        "contracts/l2/tokens/ERC20.cairo",
        constructor_calldata=[
            str_to_felt("ATTACK"),
            str_to_felt("ATTACK"),
            admin_account.contract_address,
        ]
    )

    tower_defence = await starknet.deploy(
        source="contracts/l2/minigame/01_TowerDefence.cairo",
        constructor_calldata=[
            controller.contract_address,
            attack_token.contract_address
        ]
    )
    
    tower_defence_storage = await starknet.deploy(
        source="contracts/l2/minigame/02_TowerDefenceStorage.cairo",
        constructor_calldata=[controller.contract_address]
    )

    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='batch_set_controller_addresses',
        calldata=[
            tower_defence.contract_address, tower_defence_storage.contract_address])
    return starknet, accounts, signers, arbiter, controller, attack_token, tower_defence, tower_defence_storage

@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_wall_attack(game_factory):
    temp_expiry = 1
    attack_amount = 7

    _, accounts, signers, _, _, attack_token, tower_defence, tower_defence_storage = game_factory
    
    admin_key = signers[0]
    admin_account = accounts[0]

    execution_info = await attack_token.balanceOf(admin_account.contract_address).call()
    assert execution_info.result.balance[0] == 1000

    # 

    await admin_key.send_transaction(
        account=admin_account,
        to=tower_defence.contract_address,
        selector_name="create_game",
        calldata=[
            temp_expiry
        ]
    )

    await admin_key.send_transaction(
        account=admin_account,
        to=attack_token.contract_address,
        selector_name="approve",
        calldata=[
            tower_defence.contract_address,
            attack_amount,0
        ]
    )

    execution_info = await attack_token.allowance(
        admin_account.contract_address,
        tower_defence.contract_address
    ).call()
    assert execution_info.result.remaining[0] == attack_amount

    await admin_key.send_transaction(
        account=admin_account,
        to=tower_defence.contract_address,
        selector_name="attack_wall",
        calldata=[
            1,
            attack_amount,
        ]
    )

    execution_info = await attack_token.allowance(
        admin_account.contract_address,
        tower_defence.contract_address
    ).call()
    assert execution_info.result.remaining[0] == 0

    execution_info = await attack_token.balanceOf(
        admin_account.contract_address
    ).call()
    assert execution_info.result.balance[0] == 993

    execution_info = await tower_defence_storage.get_wall_health(
        1
    ).call()
    assert execution_info.result.health == 93

