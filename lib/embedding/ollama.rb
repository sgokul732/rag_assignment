require "net/http"
require "json"

class Embedding::Ollama
    MODEL = "nomic-embed-text"
    
    def self.embed(text)
        uri = URI("http://host.docker.internal:11434/api/embeddings")
        
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        
        request.body = {
            model: MODEL,
            prompt: text
        }.to_json
        
        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request(request)
        end
    
        JSON.parse(response.body)["embedding"]
    end
end
