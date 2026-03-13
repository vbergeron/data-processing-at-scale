# Project 14 — DeFi Activity Stream Processing

**Extends:** Sessions 3.1 (Kafka), 3.2 (windowed aggregations), 4.1 (probabilistic structures)  
**Dataset:** [Ethereum](../DATASETS.md#ethereum-public-dataset-blockchain-etl) + [Sourcify](../DATASETS.md#sourcify-verified-smart-contracts)  
**Stack:** Kafka, Flink, Python

## Context

DeFi protocols (Uniswap, Aave, etc.) generate thousands of on-chain events per block. By replaying Ethereum token transfer and contract interaction logs, you can build a streaming pipeline that monitors DeFi activity in real time. Your job is to detect trading volume spikes, large swaps, and liquidity changes as they happen.

## Objectives

1. **Replay** Ethereum token transfer events chronologically into Kafka (simulate a live blockchain feed)
2. **Decode** events using Sourcify ABIs to identify swap, mint, burn, and transfer operations
3. **Implement windowed aggregations**: trading volume per token per block window, rolling unique trader count (HyperLogLog), large transfer alerts
4. **Handle chain reorganizations**: blocks can be reverted — how do you process "undo" events?

## Questions You Should Be Able to Answer

- What window size did you choose for volume aggregation? Why blocks vs wall-clock time?
- How does your HyperLogLog unique trader count compare to an exact count? What's the error?
- A chain reorg reverts the last 2 blocks. How does your pipeline handle the rollback?
- What is the state size of your stream processor after processing 1 month of data?
