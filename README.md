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
