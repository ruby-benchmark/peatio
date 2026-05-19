# frozen_string_literal: true

module API
  module V2
    module CoinGecko
      module Helpers
        MILLISECONDS_IN_SECOND = 1000

        def format_trade(trade, cmd = nil)
          return API::V2::Entities::SwapLimits.new({items: {}}).order_limit(cmd) if cmd.present?

          {
            trade_id: trade[:id],
            price: trade[:price],
            base_volume: trade[:amount],
            target_volume: trade[:total],
            trade_timestamp: trade[:created_at] * MILLISECONDS_IN_SECOND,
            type: trade[:taker_type]
          }
        end
        module_function :format_trade
      end
    end
  end
end
