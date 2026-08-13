require "net/http"
require "json"

module Generation
  class Ollama
    MODEL = "llama3.2"
    
    def self.generate(question:, context:)
      prompt = "Based on the following context, answer the question.\n\nContext:\n#{context}\n\nQuestion: #{question}\n\nAnswer:"
      
      uri = URI("http://host.docker.internal:11434/api/generate")
      
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      
      request.body = {
        model: MODEL,
        prompt: prompt,
        stream: false
      }.to_json
      
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.read_timeout = 300  # 5 minute timeout for generation
      http.open_timeout = 10
      
      response = http.request(request)
      
      JSON.parse(response.body)["response"]
    end
  end
end
