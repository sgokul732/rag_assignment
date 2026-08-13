require "pdf-reader"

class Pdf::Extractor
    def initialize(pdf_file)
        @pdf_file = pdf_file
    end
    def extract_text
        pdf = PDF::Reader.new(@pdf_file)
        pdf.pages.map(&:text).join("\n")
    end
end
