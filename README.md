# EcoThread

A blockchain-powered platform for sustainable fashion that ensures transparency in supply chains, combats counterfeiting, and provides fair royalties to designers through tokenized assets — all on-chain, promoting ethical practices in the fashion industry.

---

## Overview

EcoThread addresses real-world issues in fashion like opaque supply chains, widespread counterfeits, and lack of ongoing revenue for creators by leveraging Web3. It consists of five main smart contracts that form a decentralized ecosystem for designers, brands, and consumers:

1. **Fashion NFT Contract** – Issues and manages NFTs representing physical or digital fashion items with embedded provenance data.
2. **Marketplace Contract** – Facilitates buying, selling, and reselling with built-in royalty mechanisms.
3. **Supply Chain Tracker Contract** – Logs and verifies production steps for transparency and sustainability.
4. **Royalty Distributor Contract** – Automates royalty payouts to creators on every resale.
5. **Governance DAO Contract** – Enables community voting on sustainability standards and platform upgrades.

---

## Features

- **Tokenized fashion items** as NFTs with verifiable authenticity and sustainability metrics  
- **Decentralized marketplace** for primary sales and resales with anti-counterfeit checks  
- **Supply chain transparency** tracking materials from source to product  
- **Automatic royalty sharing** ensuring designers benefit from secondary markets  
- **DAO governance** for token holders to influence eco-friendly policies  
- **Sustainability rewards** integrated via governance for verified ethical practices  
- **Oracle integration** for real-world data on materials and production ethics  
- **Anti-counterfeit measures** through on-chain verification of item history  

---

## Smart Contracts

### Fashion NFT Contract
- Mint NFTs for fashion items (e.g., clothing, accessories) with metadata including design details, materials, and sustainability scores
- Update NFT metadata for dynamic attributes like wear history or recycling status
- Transfer and burn mechanisms with ownership verification

### Marketplace Contract
- List, buy, and sell NFTs with automated escrow for secure transactions
- Enforce resale rules, including royalty deductions
- Integration with anti-scalping limits and authenticity checks via supply chain data

### Supply Chain Tracker Contract
- Record production milestones (e.g., sourcing, manufacturing, shipping) as on-chain events
- Verify ethical practices (e.g., fair labor, eco-materials) through oracle-fed data
- Queryable history for consumers to trace item provenance

### Royalty Distributor Contract
- Calculate and distribute royalties automatically on each resale (e.g., 10% to original designer)
- Track payout history and accumulate funds in a treasury
- Multi-recipient support for collaborations (e.g., designer + brand splits)

### Governance DAO Contract
- Token-weighted voting on proposals like new sustainability criteria or fee adjustments
- On-chain execution of approved proposals
- Quorum requirements and proposal submission for community involvement

---

## Installation

1. Install [Clarinet CLI](https://docs.hiro.so/clarinet/getting-started)
2. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/ecothread.git
   ```
3. Run tests:
    ```bash
    npm test
    ```
4. Deploy contracts:
    ```bash
    clarinet deploy
    ```

## Usage

Each smart contract operates independently but integrates with others for a complete sustainable fashion ecosystem.
Refer to individual contract documentation for function calls, parameters, and usage examples.

## License

MIT License