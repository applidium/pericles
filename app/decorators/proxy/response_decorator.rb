module Proxy
  class ResponseDecorator < Draper::Decorator
    delegate_all
    decorates Response

    def errors_from_report(report)
      status_errors = errors_for_status(report.response_status_code)
      header_errors = errors_for_headers(report.response_headers)
      body_errors = status_errors.empty? ? errors_for_body(report.response_body) : []
      status_errors + header_errors + body_errors
    end

    def errors_for_status(status_code_to_check)
      status_code == status_code_to_check ? [] :
      [
        ValidationError.new(
          category: :status_code,
          description: "Status code is #{status_code_to_check} instead of #{status_code}"
        )
      ]
    end

    def errors_for_headers(headers_to_check)
      headers_names = headers_to_check.each_key.map { |h| h.to_s.downcase }
      headers.map do |h|
        next if headers_names.include? h.name.to_s.downcase
        ValidationError.new(
          category: :header,
          description: "#{h.name} is missing from the response headers"
        )
      end.compact
    end

    def errors_for_body(body_to_check)
      body_is_empty = body_to_check.length.zero?

      if json_schema.nil?
        return [] if body_is_empty
        return [ValidationError.new(category: :body, description: 'Body must be empty')]
      end

      return [ValidationError.new(category: :body, description: 'Body must not be empty')] if body_is_empty

      begin
        errors = JSON::Validator.fully_validate(
          json_schema, body_to_check, json: true
        )
      rescue JSON::Schema::JsonParseError
        return [ValidationError.new(category: :body, description: 'Body is not a valid JSON')]
      end

      return [] if errors.empty?

      [
        ValidationError.new(
          category: :body,
          description: errors.join("\n")
        )
      ]
    end
  end
end
