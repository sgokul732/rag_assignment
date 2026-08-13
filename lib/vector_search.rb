class VectorSearch
  def search(query, limit: 5)
    # Generate embedding for the query
    query_embedding = Embedding::Ollama.embed(query)
    
    # Load all chunks with their embeddings
    chunks = Chunk.select(:id, :content, :embedding).all
    
    # Calculate cosine similarity with each chunk
    scored_chunks = chunks.map do |chunk|
      chunk_embedding = chunk.embedding
      
      if chunk_embedding && chunk_embedding.is_a?(Array)
        similarity = cosine_similarity(query_embedding, chunk_embedding)
        { chunk: chunk, similarity: similarity }
      else
        { chunk: chunk, similarity: 0 }
      end
    end
    
    # Return top matches sorted by similarity (highest first)
    scored_chunks
      .sort_by { |item| -item[:similarity] }
      .take(limit)
      .map { |item| item[:chunk] }
  end
  
  private
  
  def cosine_similarity(vec1, vec2)
    return 0 if vec1.nil? || vec2.nil? || vec1.empty? || vec2.empty?
    return 0 if vec1.size != vec2.size
    
    dot_product = vec1.zip(vec2).sum { |a, b| a * b }
    norm1 = Math.sqrt(vec1.sum { |x| x * x })
    norm2 = Math.sqrt(vec2.sum { |x| x * x })
    
    return 0 if norm1.zero? || norm2.zero?
    
    dot_product / (norm1 * norm2)
  end
end
