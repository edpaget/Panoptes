require 'spec_helper'

RSpec.describe SubjectWorkflowCount, type: :model do
  let(:count) { create(:subject_workflow_count) }
  it 'should have a valid factory' do
    expect(build(:subject_workflow_count)).to be_valid
  end

  it 'should not be valid without a set_member_subject' do
    swc = build(:subject_workflow_count, set_member_subject: nil, link_subject_sets: false)
    expect(swc).to_not be_valid
  end

  it 'should not be valid without a workflow' do
    swc = build(:subject_workflow_count, workflow: nil, link_subject_sets: false)
    expect(swc).to_not be_valid
  end

  context "when there is a duplicate set_member_subject_id workflow_id entry" do
    let(:duplicate) { count.dup }

    it 'should not allow duplicates' do
      expect(duplicate).to_not be_valid
    end

    it "should raise a uniq index db error" do
      expect{duplicate.save(validate: false)}.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#retire!" do
    it 'marks the record as retired' do
      count.retire!
      count.reload
      expect(count.retired?).to be_truthy
    end

    it 'should add the workflow the set_member_subjects retired list' do
      count.retire!
      count.reload
      expect(count.set_member_subject.retired_workflows).to include(count.workflow)
    end

    it 'should increment the workflow retired subjects counter' do
      expect{count.retire!}.to change{Workflow.find(count.workflow).retired_set_member_subjects_count}.from(0).to(1)
    end

    it 'does nothing when the record is already retired' do
      count.retired_at = 5.days.ago
      expect { count.retire! }.not_to change { count.retired_at }
    end
  end

  describe "#retire?" do
    it 'should test against the workflow retirement scheme' do
      d = double
      allow(count.workflow).to receive(:retirement_scheme).and_return(d)
      expect(d).to receive(:retire?).with(count)
      count.retire?
    end
  end
end
