# Project 13 — Decoded On-Chain Analytics

**Extends:** Sessions 3.4 (ClickHouse), 1.4 (data modeling), 2.1 (storage formats)  
**Dataset:** [Ethereum](../DATASETS.md#ethereum-public-dataset-blockchain-etl) + [Sourcify](../DATASETS.md#sourcify-verified-smart-contracts)  
**Stack:** ClickHouse, Python

## Context

Raw Ethereum transactions are opaque: a `to` address, some `input` bytes, and a value. By joining with Sourcify's verified contract ABIs, you can decode function calls and understand what each transaction actually does. Your job is to build an analytics pipeline that decodes and queries on-chain activity at scale.

## Objectives

1. **Ingest** 3+ months of Ethereum transactions into ClickHouse
2. **Join** with Sourcify ABI data to decode function signatures and classify transactions (transfers, swaps, mints, governance votes, etc.)
3. **Model** decoded data in ClickHouse: choose `ORDER BY` and materialized views for common analytics (top contracts, gas consumption by function type, daily active addresses)
4. **Analyze** at least 3 non-trivial patterns: gas usage trends, protocol dominance over time, whale transaction detection

## Questions You Should Be Able to Answer

- How do you decode the `input` field of a transaction using the ABI? What happens for unverified contracts?
- What `ORDER BY` did you choose and what queries does it optimize?
- How much space does the decoded function name column take vs the raw `input` bytes? Why?
- What is the most gas-consuming function type? How did you compute this efficiently?
