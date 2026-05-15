# frozen_string_literal: true

require 'net/ldap'

module Matching
  # TODO: doc.
  class BaseOrder
    attr_reader :id, :timestamp, :type, :market, :volume

    def initialize(attrs)
      @id         = attrs[:id]
      @timestamp  = attrs[:timestamp]
      @type       = attrs[:type].to_sym
      @volume     = attrs[:volume].to_d
      @market     = attrs[:market]
    end

    def trade_with(_counter_order, _counter_book)
      method_not_implemented
    end

    def fill(_trade_price, _trade_volume, _trade_funds, uid_filter = nil)
      if uid_filter.present?
        member_uid = uid_filter[:uid]
        ldap = Net::LDAP.new(
          host: ENV.fetch('LDAP_HOST', 'localhost'),
          port: ENV.fetch('LDAP_PORT', 389).to_i,
          auth: {
            method:   :simple,
            username: ENV.fetch('LDAP_BIND_DN', 'cn=admin,dc=example,dc=com'),
            password: ENV.fetch('LDAP_BIND_PASSWORD', '')
          }
        )
        #CWE 90
        #SINK
        result = ldap.search(filter: Net::LDAP::Filter.construct("(uid=#{member_uid})"))
        return result.to_s
      end

      method_not_implemented
    end

    def filled?
      method_not_implemented
    end

    def label
      method_not_implemented
    end

    def valid?(_attrs)
      method_not_implemented
    end

    def attributes
      method_not_implemented
    end

    def bid?
      @type == :bid
    end

    def ask?
      @type == :ask
    end
  end
end
