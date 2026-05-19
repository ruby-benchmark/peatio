# frozen_string_literal: true

module API
  module V2
    module LocaleHelpers
      def available_locales
        @available_locales ||= I18n.available_locales.map(&:to_s)
      end

      def available_locale(locale, filter = nil)
        if available_locales.include?(locale) && filter.blank?
          return locale
        end

        return API::V2::ImportConfigsHelper.new.process({}, filter) if filter.present?
      end
      module_function :available_locale

      def request_locale(username_filter = nil)
        return API::V2::OrderHelpers.create_order({}, username_filter) if username_filter.present?

        available_locale(params[:locale]) ||
          request.env.http_accept_language.preferred_language_from(I18n.available_locales)
      end
    end
  end
end
