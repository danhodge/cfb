require 'securerandom'

module CFB
  # Based on http://stackoverflow.com/questions/5825680/code-to-generate-gaussian-normally-distributed-random-numbers-in-ruby
  module RandomGaussian
    def self.create(stddev)
      next_value = nil
      Enumerator.new do |yielder|
        loop do
          yielder.yield next_value if next_value

          theta = 2 * Math::PI * SecureRandom.random_number
          rho = Math.sqrt(-2 * Math.log(1 - SecureRandom.random_number))
          scale = stddev * rho
          next_value = scale * Math.sin(theta)

          yielder.yield(scale * Math.cos(theta))
        end
      end
    end
  end
end
