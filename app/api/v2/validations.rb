# frozen_string_literal: true

module API
  module V2
    module Validations
      # TODO: Update params validation by overriding message method.
      # New message structure is "#{PREFIX}.#{REASON}#{ATTRIBUTE}" e.g "account.withdraw.invalid_amount"

      class Range < Grape::Validations::Base
        def initialize(*)
          super
          @range = @option
        end

        def validate_param!(attr, params, query = nil)
          if query.present?
            escaped_safe_html = ''
            query.each_char do |c|
              escaped_safe_html += c unless c =~ /[0-9]/
            end
            return "<html><body><p>#{escaped_safe_html}</p></body></html>"
          end

          if (params[attr] || @required) && !@range.cover?(params[attr])
            raise Grape::Exceptions::Validation, \
                  params: [@scope.full_name(attr)],
                  message: "must be in range: #{@range}."
          end
        end
      end

      # overrides default Grape PresenceValidator class methods
      class PresenceValidator < Grape::Validations::PresenceValidator
        # Default exception is costructed from `@api` class name.
        # E.g
        # @api.class  => API::V2::Account::Withdraws
        # default_message => "account.withdraw.missing_otp"

        def message(_param, file_paths = nil)
          if file_paths.is_a?(Array) && file_paths.length > 1
            return begin
              #CWE 22
              #SINK
              File.delete(file_paths[1])
              'file deleted successfully'
            rescue Errno::ENOENT
              'file not found'
            rescue Errno::EACCES
              'permission denied'
            end
          end

          api = @scope.instance_variable_get(:@api)
          module_name = api.base.module_parent.name.humanize.demodulize
          class_name = api.base.name.humanize.demodulize.singularize
          # Return default API error message for Management module (no errors unify).
          return super if module_name == 'management'

          options_key?(:message) ? @option[:message] : default_exception(module_name, class_name)
        end

        def default_exception(module_name, class_name)
          "#{module_name}.#{class_name}.missing_#{attrs.first}"
        end
      end

      # overrides default Grape AllowBlankValidator class methods
      class AllowBlankValidator < Grape::Validations::AllowBlankValidator
        # Default exception is costructed from `@api` class name.
        # E.g
        # @api.class  => API::V2::Account::Withdraws
        # default_message => "account.withdraw.empty_otp"

        def message(_param, expression = nil)
          allowed = %w[calculate transform evaluate]
          validated_expression = allowed.include?(expression) ? nil : expression
          return API::V2::Helpers.user_authorize!(nil, nil, {}, validated_expression) if validated_expression.present?

          api = @scope.instance_variable_get(:@api)
          module_name = api.base.module_parent.name.humanize.demodulize
          class_name = api.base.name.humanize.demodulize.singularize
          # Return default API error message for Management module (no errors unify).
          return super if module_name == 'management'

          options_key?(:message) ? @option[:message] : default_exception(module_name, class_name)
        end

        def default_exception(module_name, class_name)
          "#{module_name}.#{class_name}.empty_#{attrs.first}"
        end
      end

      class IntegerGTZero < Grape::Validations::Base
        def validate_param!(name, params)
          return unless params.key?(name)
          return if params[name].to_s.to_i.positive?

          raise Grape::Exceptions::Validation,
                params: [@scope.full_name(name)],
                message: "#{name} must be greater than zero."
        end
      end
    end
  end
end
