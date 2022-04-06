# Realms Settling Game

### The Realms Settling Game - based on the Realms derivative NFT of the Loot Project

A modular game engine architecture for the StarkNet L2 roll-up - Forked & heavily inspired by the pioneering work done by the Dope Ware RYO game [here](https://github.com/dopedao/RYO).

## What is the game?

Settling is an on-chain game of economics and Chivarly built on-top of ZK-STARKS. Earn resources by staking your Realms, raid rivals, steal loot & form on-chain alliances to crush your enemies.

Settling is entirely on-chain; the UI is purely just a client for a distributed backend. Feel free to create your own superior client if you wish.

Picture a million players all asynchronously working the blockchain; harvesting resources, building alliances, & slaying foes. This is Settling.

Settling is all open-source and we encourage people to build modules and contribute.

Requirements: To play be a Lord you require a Realm from the Lootverse. The game will support more Loot derivatives in the future to enrich the gameplay.
<hr>

## System architecture

The game mechanics are separated from the game state variables.

A controller system manages a mapping of modules to deployed addresses and a governance module may update the controller.

For example all these modules could read and write from the state modules and be connected-but-distinct game interactions:

<hr>

## Contract hierarchy

It is also worth pointing out that StarkNet has account abstraction
(see background notes [here](https://perama-v.github.io/cairo/examples/test_accounts/)).
This means that transactions are actioned by sending a payload to a personal
Account contract that holds your public key. The contract checks the payload
and forwards it on to the destination.

- Player Account
    - A Lord in the Realmverse. These are holders of Realms.
- Governance Account
    - An admin who controls the Arbiter.
    - The admin may be an L2 DAO to administer governance decisions
    voted through on L2, where voting will be cheap.
    - Governance might enable a new module to have write-access to
    and important game variable. For example, to change the location
    that a player is currently in. All other modules that read and use location
    would be affected by this.
- Arbiter (most power in the system).
    - Can update/add module mappings in ModuleController.
- ModuleController (mapping of deployments to module_ids).
    - The game 'swichboard' that connects all modules.
    - Is the reference point for all modules. Modules call this
    contract as the source of truth for the address of other modules.
    - The controller stores where modules can be found, and which modules
    have write access to other modules.
- Modules (open ended set)
    - Game mechanics (where a player would interact to play). 
    - Storage modules (game variables).
    - L1 connectors (for integrating L1 state/ownership to L2)
    - Other arbitrary contracts
    - Module logic contained in A (e.g 02A_Settling.cairo) and state in B (02B_Settling.cairo)

For more information see

- Modular [system architecture](./system_architecture.md).
- Descriptions of example modules in [module notes](/module_notes).

<hr>

## Setup

Clone this repo and use our docker shell to interact with starknet:

```
git clone git@github.com:BibliothecaForAdventurers/RealmsSettling.git
cd RealmsSettling
bin/shell starknet --version
```

The CLI allows you to deploy to StarkNet and read/write to contracts
already deployed. The CLI communicates with a server that StarkNet
runs, which bundles the requests, executes the program (contracts are
Cairo programs), creates and aggregates validity proofs, then posts them
to the Goerli Ethereum testnet. Learn more in the Cairo language and StarkNet
docs [here](https://www.cairo-lang.org/docs/), which also has instructions for manual
installation if you are not using docker.

### Development workflow

If you are using VSCode, we provide a development container with all required dependencies.
When opening VS Code, it should ask you to re-open the project in a container, if it finds
the .devcontainer folder. If not, you can open the Command Palette (`cmd + shift + p`),
and run “Remote-Containers: Rebuild and Reopen in Container”.

## Outline

Flow:

1. Compile the contract with the CLI
2. Test using pytest
3. Deploy with CLI
4. Interact using the CLI or the explorer

### Compile

The compiler will check the integrity of the code locally.
It will also produce an ABI, which is a mapping of the contract functions
(used to interact with the contract).

Compile all contracts:
```
nile compile
```

Compile an individual contract:
```
nile compile contracts/02A_Settling.cairo
```

### Test

Run all github actions tests: `bin/test`

Run individual tests
```
bin/shell pytest -s testing/l2/01_Realms_contract_test.py
```

### Deploy

Start up a local StarkNet devnet with:
```
nile node
```
Then run the deployment of all the contracts. This uses nile
and handles passing addresses between the modules to create a
permissions system.
```
bin/deploy
```
<hr>

## Contributing and Nextsteps

Module Priority
1. Settling
2. Construction
3. Resource Upgrading
4. Army Building
5. Raiding

Building out parts to make a functional `v1`

## Binary bit encoding

To minimise storage costs (we should always do this where we can) we back felts with binary numbers

For the Realms Data we are storing all the traits, resources and wonders within a single felt.

This technique was borrowed from the Dopewars engine (credit goes to @eth_worm)

#### Define the values in binary

```
struct RealmData:
    member cities : felt  # eg: 7 citees = 111 
    member regions : felt  # eg: 4 regions = 100 
    member rivers : felt  # eg: 60 rivers = 111100 
    member harbours : felt  #  eg: 10 harbours = 1010 
    member resource_number : felt  #  eg: 4 resource_number = 100 
    member resource_1 : felt  # eg: 5 resource_1 = 101 
    member resource_2 : felt  # eg: 10 resource_2 = 1010 
    member resource_3 : felt  # eg: 12 resource_3 = 1100 
    member resource_4 : felt  # eg: 21 resource_4 = 10101
    member resource_5 : felt  # eg: 9 resource_5 = 1001
    member resource_6 : felt  # eg: 10 resource_6 = 0 (0 if no resource)
    member resource_7 : felt  # eg: 10 resource_7 = 0 (0 if no resource)
    member wonder : felt  # eg: 50 wonder = 110010 (50 wonders)  
end
```

#### Pack binary bits

Define our large the mask is needed for a value.

We will use rivers as an example since it's highest value is 60, which equates to 7 bits. So we will use an 8 bit mask on all values to keep things consistent (this could be what ever you like)

So starting from the first value, take the bit number and add on 0 to make an 8 bit number

eg: 
trait    bit   8 bit number

cities = 111 = 00000111
regions = 100 = 00000100
rivers = 111100 = 00111100
harbours = 1010 = 00001010
resource_number = 00000101
resource_1 = 00000101 
resource_2 = 00001010 
resource_3 = 00001100 
resource_4 = 00010101
resource_5 = 00001001
resource_6 = 00000000 
resource_7 = 00000000
wonder = 00110010
order = 00000010

Then concatanate the values
0000001000110010000000000000000000001001000101010000110000001010000001010000010100001010001111000000010000000111


Then convert to decimal and this is the realms traits to store in the felt:

```
44526227375906105210343834518535
```

Then this function will unpack the the decimal into bits

```
unpack_realm_data()
```


Same method is used for packing the values of resources needed to upgrade a resource

```
resource_1 = 5 = 00000101
resource_2 = 10 = 00001010  
resource_3 = 12 = 00001100
resource_4 = 21 = 00010101
resource_5 = 9 = 00001001
resource_1_values = 00001010
resource_2_values = 00001010   
resource_3_values = 00001010     
resource_4_values = 00001010   
resource_5_values = 00001010

00001010000010100000101000001010000010100000100100010101000011000000101000000101

47408855671157818132997
```