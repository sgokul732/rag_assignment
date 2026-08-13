class Pdf::Ingestor
    def self.import(file)
        text = Pdf::Extractor.new(file).extract_text
        text = Pdf::Cleaner.clean(text)
        
        document = Document.create!(
            title: File.basename(file),
            source: file
        )

        Chunking::TextChunker.new(text).chunks.each do |chunk|
            document.chunks.create!(
                content: chunk,
                embedding: Embedding::Ollama.embed(chunk),
                embedding_model: Embedding::Ollama::MODEL
            )
        end

        document
    end
end
