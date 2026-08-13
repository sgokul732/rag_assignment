class Pdf::Cleaner
    
    def self.clean(text)
        text
            .gsub(/\s+/, " ")
            .strip
    end
end
