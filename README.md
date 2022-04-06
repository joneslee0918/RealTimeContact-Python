[![Discord](https://badgen.net/badge/icon/discord?icon=discord&label)](https://discord.gg/uQnjZhZPfu)
[![Twitter](https://badgen.net/badge/icon/twitter?icon=twitter&label)](https://twitter.com/LootRealms)

![This is an image](/R_-100.jpg)

# 📝 Realms Contracts

Realms is an ever-expanding on-chain permission-less gaming Lootverse built on StarkNet. 

This monorepo contains all of the Contracts (StarkNet/Cairo Ethereum/Solidity) for BibliothecaDAO, $LORDS, and Realms.

## Contracts
| Directory | Title | Description                     |
| --------- | ----- | ------------------------------- |
| **[/settling_game](./contracts/settling_game)** | The Realms Settling Game | A modular game engine architecture built on StarkNet. |
| [/desiege](./contracts/desiege) | Desiege | A web-based team game built on Starknet. |
| [/token](./contracts/token) | $LORDS | An ERC20 asset underpinning the Realmverse and beyond. |
| [/L1-Solidity](./contracts/L1-Solidity/) | L1 contracts | A set of L1 contracts including the Journey ($LORDS staking). |
| [/openzeppelin](./contracts/openzeppelin/) | 
| [/game_utils](./contracts/game_utils) | Game Utils | Game utility contracts such as grid positions written in Cairo. |
| [/loot](./contracts/loot/) | Loot contracts ported to Cairo. |
| [/nft_marketplace](./contracts/nft_marketplace/) | A marketplace for Realms, Dungeons, etc. built on Starknet. |
| [/utils](./contracts/utils) | Cairo utility contracts | Helper contracts such as safemath written in Cairo. |


## Learn More about Realms

First, visit the [Bibliotheca DAO Site](https://bibliothecadao.xyz/) for an overview of our ecosystem.

Next, read the [Master Scroll](https://docs.bibliothecadao.xyz/lootverse-master-scroll/). This is our deep dive into everything about the game. The Master Scroll is the source of truth before this readme.

Finally, visit [The Atlas](https://atlas.bibliothecadao.xyz/) to see the Settling game in action.

If you want to get involved, join the [Realms x Bibliotheca Discord](https://discord.gg/uQnjZhZPfu).


## Contributing

<details><summary>How to contribute</summary>

We encourage pull requests.

</details>
<hr>

## Realms Repositories

The Realms Settling Game spans a number of repositories:

| Content         | Repository       | Description                                              |
| --------------- | ---------------- | -------------------------------------------------------- |
| **contracts**       | [realms-contracts](https://github.com/BibliothecaForAdventurers/realms-contracts) | StarkNet/Cairo and Ethereum/solidity contracts.          |
| **ui, atlas**       | [realms-react](https://github.com/BibliothecaForAdventurers/realms-react)     | All user-facing react code (website, Atlas, ui library). |
| **indexer**         | [starknet-indexer](https://github.com/BibliothecaForAdventurers/starknet-indexer) | A graphql endpoint for the Lootverse on StarkNet.        |
| **bot**             | [squire](https://github.com/BibliothecaForAdventurers/squire)           | A Twitter/Discord bot for the Lootverse.                 |
| **subgraph**        | [loot-subgraph](https://github.com/BibliothecaForAdventurers/loot-subgraph)    | A subgraph (TheGraph) for the Lootverse on Eth Mainnet.  |
