module OandaAPI
  # Errors raised by the client.
  class RequestError < RuntimeError; end
  class StreamingDisconnect < RuntimeError; end
end
