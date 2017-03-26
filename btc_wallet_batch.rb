require 'digest'
require 'digest/bubblebabble'
require 'bip_mnemonic'
require 'rqrcode'
require 'money-tree'
require 'shamir-secret-sharing'
require 'highline/import'
require 'openssl'

SALT="TylersSafeAndReproducibleWallets"

def get_password
  pw  = ask("Enter password:") {|q| q.echo = false}
  pw2 = ask("Enter password again:") {|q| q.echo = false}

  if pw == pw2
    pw
  else
    nil
  end
end

def pw_entropy(pw, hashes: 100_000)
  OpenSSL::PKCS5.pbkdf2_hmac(pw, SALT, hashes, 512, OpenSSL::Digest::SHA512.new)
end

def pw_to_mnemonic(pw)
  BipMnemonic.to_mnemonic(entropy: pw_entropy(pw)[0..31])
end

def pw_to_seed(pw)
  BipMnemonic.to_seed(mnemonic: pw_to_mnemonic(pw))
end

def securerandom_seed_entropy(entropy, rot)
  r = entropy.split(',').map(&:to_i)
  r.rotate(rot)[0..15].pack("C*").unpack("H*")[0]
end

def securerandom_seed_to_mnemonic(entropy, rot=0)
  BipMnemonic.to_mnemonic(entropy: securerandom_seed_entropy(entropy, rot)[0..31])
end

def securerandom_seed_to_seed(entropy, rot=0)
  BipMnemonic.to_seed(mnemonic: securerandom_seed_to_mnemonic(entropy, rot))
end

def wallet_batch(size, seed: nil)
  if !seed
    passwords_dont_match = true
    while passwords_dont_match do
      pw = get_password
      passwords_dont_match = false if pw
    end
    seed = pw_to_seed(pw)
  end

  master = MoneyTree::Master.new(seed_hex: seed)
  timestamp = Time.now.to_s

  (0).upto(size-1).map do |ix|
    node = master.node_for_path("m/44p/0p/#{ix}p/0/0")
    pub = node.to_address
    prv = node.private_key.to_wif

    { type: :single,
      pub: pub,
      prv: prv,
      qrpub: Base64::encode64(RQRCode::QRCode.new("bitcoin:#{pub}").as_png.to_blob),
      qrprv: Base64::encode64(RQRCode::QRCode.new("bitcoin:#{prv}").as_png.to_blob),
      timestamp: timestamp,
      id: Digest::SHA256.bubblebabble("#{timestamp} / #{ix}").split('-')[1..3].join('-') }
  end
end

def split_wallet_batch(size, thresh: nil, acct_no: 1, seed: nil)
  if !seed
    passwords_dont_match = true
    while passwords_dont_match do
      pw = get_password
      passwords_dont_match = false if pw
    end
    seed = pw_to_seed(pw)
  end

  raise "acct_no must be >= 1" if acct_no < 1
  master = MoneyTree::Master.new(seed_hex: seed)
  timestamp = Time.now.to_s
  thresh = size - 1 if thresh.nil?
  node = master.node_for_path("m/#{acct_no}p/0")
  pub = node.to_address
  prv = node.private_key.to_wif
  shares = ShamirSecretSharing::Base58.split(prv, size, thresh)

  shares.map do |share|
    { type: :split,
      threshold: thresh,
      pub: pub,
      share: share,
      qrpub: Base64::encode64(RQRCode::QRCode.new("bitcoin:#{pub}").as_png.to_blob),
      qrshare: Base64::encode64(RQRCode::QRCode.new(share).as_png.to_blob),
      timestamp: timestamp }
  end
end

def combine_split_wallets(shares)
  raise "shares don't match" if shares.map { |share| share.values_at(:pub, :threshold) }.uniq.size > 1
  raise "not enough shares" if shares.size < shares[0][:threshold]
  pub = shares[0][:pub]
  shares = shares.map { |share| share[:share] }

  { type: :single,
    pub: pub,
    prv: ShamirSecretSharing::Base58.combine(shares) }
end
