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

# SporeSpawn

A Ruby interface to regenerate Mycelium wallets on the desktop from your 12-word passphrase.

### Usage (Ruby console)

```
wallet = SporeSpawn::Wallet.new('pass phrase')
wallet.balance # -> balance in Satoshis
wallet.bitcoins # -> balance in Bitcoins
wallet.to_wallet_dat # -> convert to wallet.dat file

```

### Blockchain

SporeSpawn searches the Bitcoin blockchain for your information using the free blockchain.info API. It does not send any sensitive information such as private keys, however, it does send public keys (for both internal and external addresses) in order to get your balance.
