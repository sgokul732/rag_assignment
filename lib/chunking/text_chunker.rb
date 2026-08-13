class Chunking::TextChunker
    def initialize(text, size: 500, overlap: 100)
        @text = text
        @size = size
        @overlap = overlap
    end
    def chunks
        words = @text.split
        result = []
        index = 0
        while index < words.length
            result << words[index, @size].join(" ")
            index += (@size - @overlap)
        end
        result
    end
end
