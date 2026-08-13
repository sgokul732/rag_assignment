require "yaml"

module Evaluation
    class RagEvaluator
        def initialize(session_id: "evaluation")
            @session_id = session_id
        end

        def evaluate
            questions = YAML.load_file(
                Rails.root.join("config/evaluation_questions.yml")
            )["questions"]
            
            results = questions.map { |item| evaluate_question(item) }
            
            {
                total: results.size,
                passed: results.count { |r| r[:passed] },
                accuracy: accuracy(results),
                details: results
            }
        end

        private

        def evaluate_question(item)
            chunks = VectorSearch.new.search(item["question"])
            context = chunks.map(&:content).join("\n\n")
            
            answer = Generation::Ollama.generate(
                question: item["question"],
                context: context
            )

            passed = item["expected_keywords"].all? do |keyword|
                answer.to_s.downcase.include?(keyword.downcase)
            end
            {
                question: item["question"],
                expected_keywords: item["expected_keywords"],
                answer: answer,
                passed: passed
            }   
        end
        
        def accuracy(results)
            return 0 if results.empty?
            ((results.count { |r| r[:passed] }.to_f / results.size) * 100).round(2)
        end
    end
end
