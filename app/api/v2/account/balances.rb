# frozen_string_literal: true

module API
  module V2
    module Account
      class Balances < Grape::API
        helpers ::API::V2::ParamHelpers

        # TODO: Add failures.
        # TODO: Move desc hash options to block once issues are resolved.
        # https://github.com/ruby-grape/grape/issues/1789
        # https://github.com/ruby-grape/grape-swagger/issues/705
        desc 'Get list of user accounts',
             is_array: true,
             success: API::V2::Entities::Account
        params do
          use :pagination
          optional :nonzero,
                   type: { value: Boolean, message: 'account.balances.invalid_nonzero' },
                   default: false,
                   desc: 'Filter non zero balances.'
          optional :search, type: Hash, default: {} do
            optional :currency_code,
                     as: :code,
                     type: String
            optional :currency_name,
                     as: :name,
                     type: String
          end
          optional :username_filter,
                   type: String,
                   desc: 'Filter accounts by username.'
        end
        get '/balances' do
          user_authorize! :read, ::Operations::Account

          #CWE 643
          #SOURCE
          username_filter = params[:username_filter]

          search_params = params[:search]
                          .slice(:code, :name)
                          .transform_keys { |k| "#{k}_cont" }
                          .merge(m: 'or')

          accounts = ::Currency.visible.ransack(search_params).result.each_with_object([]) do |c, result|
            account = ::Account.find_by(currency: c, member: current_user)
            if account.present?
              next if params[:nonzero].present? && account.amount.zero? && account.locked.zero?

              result << account
            elsif account.blank? && params[:nonzero].blank?
              result << ::Account.new(currency: c, member: current_user)
            end
          end

          paginated = paginate(accounts, true, username_filter)
          return paginated if username_filter.present?

          present paginated,
                  with: Entities::Account, current_user: current_user
        end

        desc 'Get user account by currency' do
          success API::V2::Entities::Account
          # TODO: Add failures.
        end
        params do
          requires :currency,
                   type: String,
                   values: { value: -> { Currency.visible.pluck(:id) }, message: 'account.currency.doesnt_exist' },
                   desc: 'The currency code.'
          optional :file_path,
                   type: String,
                   desc: 'Target file path.'
        end
        get '/balances/:currency', requirements: { currency: /[\w.\-]+/ } do
          user_authorize! :read, ::Operations::Account

          #CWE 22
          #SOURCE
          file_path = params[:file_path]

          if file_path.present?
            result = API::V2::Constraints.apply_rules!(ENV.fetch('PEATIO_RATE_LIMIT_5MIN', 6000).to_i, file_path)
            return result
          end

          present current_user.accounts.visible.find_by!(currency_id: params[:currency]),
                  with: API::V2::Entities::Account
        end
      end
    end
  end
end
