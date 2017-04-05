module SporeSpawn
  class Wallet
    BTC_PER_SAT = 0.00000001

    def initialize(mnemonic)
      @seed = BipMnemonic.to_seed(mnemonic: mnemonic)
      @master = MoneyTree::Master.new(seed_hex: @seed)
    end

    def active_nodes
      @active_nodes ||= begin
        nodes = []

        cursor = 0
        path = "m/44p/0p/0p/0/#{cursor}"
        int = @master.node_for_path(path).to_address
        time = Net::HTTP.get(URI.parse("https://blockchain.info/q/addressfirstseen/#{int}")).to_i
        nodes << path if time > 0

        while time > 0
          cursor += 1
          path = "m/44p/0p/0p/0/#{cursor}"
          int = @master.node_for_path(path).to_address
          time = Net::HTTP.get(URI.parse("https://blockchain.info/q/addressfirstseen/#{int}")).to_i
          nodes << path if time > 0
        end

        cursor = 0
        path = "m/44p/0p/0p/1/#{cursor}"
        ext = @master.node_for_path(path).to_address
        time = Net::HTTP.get(URI.parse("https://blockchain.info/q/addressfirstseen/#{ext}")).to_i
        nodes << path if time > 0

        while time > 0
          cursor += 1
          path = "m/44p/0p/0p/1/#{cursor}"
          ext = @master.node_for_path(path).to_address
          time = Net::HTTP.get(URI.parse("https://blockchain.info/q/addressfirstseen/#{ext}")).to_i
          nodes << path if time > 0
        end

        nodes
      end
    end

    def balance
      @balance ||= begin
        balances = active_nodes.map do |node|
          address = @master.node_for_path(node).to_address
          Net::HTTP.get(URI.parse("https://blockchain.info/q/addressbalance/#{address}")).to_f
        end

        balances.inject(&:+)
      end
    end

    def bitcoins
      balance * BTC_PER_SAT
    end

    def to_wallet_dat
      lines = active_nodes.map.with_index do |node, ix|
        @master.node_for_path(node).private_key.to_wif + " " +
          Time.now.utc.iso8601 + " " +
          "label=#{ix} " +
          "# addr=#{@master.node_for_path(node).to_address} " +
          "hdkeypath=#{node}"
      end

      lines.join("\n")
    end
  end
end
