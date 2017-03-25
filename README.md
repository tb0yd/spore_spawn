# BTC Wallet Batch

I created this because I wanted to play around with the various specs surrounding HD wallets, such as BIP32, BIP39, and BIP44, in my primary language of Ruby.

The idea is that I want to be able to generate a large number of wallets securely from a single password, while making them compatible with the available wallet software and optionally recoverable later.

### Methods

```
#get_password()
#pw_entropy(pw, hashes: 100_000)
#pw_to_mnemonic(pw)
#pw_to_seed(pw)
#securerandom_seed_entropy(entropy, rot)
#securerandom_seed_to_mnemonic(entropy, rot=0)
#securerandom_seed_to_seed(entropy, rot=0)
#wallet_batch(size, seed: nil)
#split_wallet_batch(size, thresh: nil, acct_no: 1, seed: nil)
#combine_split_wallets(shares)
```
