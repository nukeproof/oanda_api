module OandaAPI
  # Request errors raised by the client.
  class RequestError < RuntimeError; end

  # Raised when the streaming API server disconnects the client
  class StreamingDisconnect < RuntimeError; end
end
