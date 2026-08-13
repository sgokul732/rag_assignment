require "httparty"
require "fileutils"

class Pdf::Downloader

PDF_FILES = {
 attention: "https://arxiv.org/pdf/1706.03762.pdf",
 bert: "https://arxiv.org/pdf/1810.04805.pdf",
 rag: "https://arxiv.org/pdf/2005.14165.pdf",
 t5: "https://arxiv.org/pdf/1910.10683.pdf",
 xlnet: "https://arxiv.org/pdf/1907.11692.pdf"
}

    def self.download_all
        folder = Rails.root.join("storage/pdfs")
        FileUtils.mkdir_p(folder)
    
        PDF_FILES.each do |name, url|
            file = folder.join("#{name}.pdf")
        
            unless File.exist?(file)
                response = HTTParty.get(url)
                File.binwrite(file, response.body)
                puts "#{name}.pdf downloaded"
            end
        end
    end
end
