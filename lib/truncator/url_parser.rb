using Truncator::ExtendedURI
using Truncator::ExtendedString
using Truncator::ExtendedArray

module Truncator
  class UrlParser
    class << self
      URL_VALID_SYMBOLS = %Q{[#{Regexp.escape('!#$&-;=?-[]_~')}a-zA-Z0-9]}
      SEPARATOR = '...'
      String.separator = SEPARATOR

      def shorten_url(uri, truncation_length = 42)
        uri = URI(uri)

        if not uri.ordinary_hostname?
          if uri.query
            uri.query_parameters = [uri.query_parameters.first]
            return uri.to_s + SEPARATOR
          else
            return uri.to_s
          end
        end

        return uri.special_format if uri.special_format.valid_length?(truncation_length)

        if uri.path_blank? and not uri.query
          return uri.special_format.truncate!(truncation_length)
        end

        if uri.query
          if uri.host.invalid_length?(truncation_length) and uri.last_path_with_query.length > truncation_length
            uri = truncate_last_directory(uri, truncation_length)
          elsif uri.special_format.valid_length?(truncation_length + uri.last_path_with_query.length) or not uri.path_blank?
            return uri.special_format.truncate!(truncation_length)
          end
        else
          if uri.host.valid_length?(truncation_length)
            uri = truncate_by_shortest(uri, truncation_length)
          else
            uri = truncate_all_directories(uri)
            uri = truncate_last_directory(uri, truncation_length)
          end
        end

        uri.special_format
      end

      private
        def truncate_all_directories(uri)
          uri = uri.dup
          paths = uri.paths
          if paths.size > 1
            uri.paths = [SEPARATOR, paths.last]
          end
          uri
        end

        def truncate_last_directory(uri, truncation_length)
          uri = uri.dup
          last_path_with_query = uri.last_path_with_query
          uri.last_path_with_query = last_path_with_query.truncate(truncation_length)
          uri
        end

        def truncate_by_shortest(uri, target_length)
          uri = uri.dup
          paths = uri.paths[0..-2]
          sorted_sequences = paths.sequences.uniq.map { |i| i.join('/') }.lazy.with_index.sort_by { |a, i| [a.size, i] }.map(&:first)
          truncated_area = sorted_sequences.find do |seq|
            (uri.special_format.length - seq.length + SEPARATOR.length) <= target_length
          end

          uri.path = uri.path.sub(truncated_area, SEPARATOR)
          uri
        end
    end
  end
end
