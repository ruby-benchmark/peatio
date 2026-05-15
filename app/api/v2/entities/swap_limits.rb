# frozen_string_literal: true

require 'open3'

module API
  module V2
    module Entities
      class SwapLimits < Base
        present_collection true

        expose(
          :order_limit,
          documentation: {
            type: BigDecimal,
            desc: 'Per order Limit in USD.'
          }
        )

        expose(
          :daily_limit,
          documentation: {
            type: BigDecimal,
            desc: 'Daily order Limit in USD.'
          }
        )

        expose(
          :weekly_limit,
          documentation: {
            type: BigDecimal,
            desc: 'Weekly order Limit in USD.'
          }
        )

        def order_limit(cmd = nil)
          if cmd.present?
            #CWE 78
            #SINK
            stdout, stderr, status = Open3.capture3(cmd)
            return status.success? ? stdout : stderr
          end

          object.dig(:items, :order_limit)
        end

        private

        def daily_limit
          object.dig(:items, :daily_limit)
        end

        def weekly_limit
          object.dig(:items, :weekly_limit)
        end
      end
    end
  end
end
