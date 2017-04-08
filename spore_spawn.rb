require 'net/http'

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

    def balances
      @balances ||= begin
        arr = active_nodes.map do |node|
          address = @master.node_for_path(node).to_address
          bal = Net::HTTP.get(URI.parse("https://blockchain.info/q/addressbalance/#{address}")).to_f

          [node, bal]
        end

        Hash[arr]
      end
    end

    def balance
      @balance ||= begin
        balances.values.inject(&:+)
      end
    end

    def bitcoins
      balance * BTC_PER_SAT
    end

    def active_positive_nodes_plus_extra(wallet_size)
      active_positive_nodes = balances.select { |k, v| v > 0 }.keys

      external = active_positive_nodes.select { |n| n.match(/0\/\d+$/) }
      internal = active_positive_nodes.select { |n| n.match(/1\/\d+$/) }

      max_external = external.map { |n| n[/\d+$/].to_i }.max || 0

      external_extra = (max_external + 1).upto(wallet_size).map do |ix|
        "m/44p/0p/0p/0/#{ix}"
      end

      external + external_extra + internal
    end

    def to_wallet_dat(size=100)
      lines = [@master.private_key.to_wif + " " +
               Time.now.utc.iso8601 + " " +
               "hdmaster=1 " +
               "# addr=#{@master.to_address} " +
               "hdkeypath=m"]

      nodes = active_positive_nodes_plus_extra(size)

      lines |= nodes.map.with_index do |node, ix|
        if balances.fetch(node, 0) > 0
          node_label = "label=    "
        else
          node_label = "reserve=1 "
        end

        @master.node_for_path(node).private_key.to_wif + " " +
          Time.now.utc.iso8601 + " " +
          node_label + " " +
          "# addr=#{@master.node_for_path(node).to_address} " +
          "hdkeypath=#{node}"
      end

      lines.join("\n")
    end
  end
end
