module Formatter
  module CSV
    class Classification
      attr_reader :classification, :project

      delegate :workflow_id, :created_at, :gold_standard, to: :classification

      def self.project_headers
        %w( user_id user_ip workflow_id created_at
            gold_standard expert metadata annotations
            linked_subjects_data )
      end

      def initialize(classification, project)
        @classification = classification
        @project = project
      end

      def to_array
        self.class.project_headers.map do |attribute|
          send(attribute)
        end
      end

      private

      def project_name
        project.name
      end

      def user_id
        if user_id = classification.user_id
          "#{user_id}".hash
        end
      end

      def user_ip
        classification.user_ip.to_s
      end

      def subject_ids
        classification.subject_ids.join(", ")
      end

      def metadata
        classification.metadata.to_json
      end

      def annotations
        classification.annotations.to_json
      end

      def expert
        classification.expert_classifier
      end
    end
  end
end
