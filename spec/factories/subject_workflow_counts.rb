FactoryGirl.define do
  factory :subject_workflow_count do
    transient do
      link_subject_sets true
    end
    set_member_subject
    workflow
    classifications_count 1

    after(:build) do |swc, env|
      if env.link_subject_sets && swc.workflow && swc.workflow.subject_sets.empty?
        swc.workflow.subject_sets << swc.set_member_subject.subject_set
      end
    end
  end
end
