require 'spec_helper'

describe Classification, :type => :model do
  it "should have a valid factory" do
    expect(build(:classification)).to be_valid
  end

  it "must have a project" do
    expect(build(:classification, project: nil)).to_not be_valid
  end

  it "must have a set_member_subject" do
    expect(build(:classification, set_member_subject: nil)).to_not be_valid
  end

  it "must have a workflow" do
    expect(build(:classification, workflow: nil)).to_not be_valid
  end

  it "must have a user_ip" do
    expect(build(:classification, user_ip: nil)).to_not be_valid
  end

  it "must have annotations" do
    expect(build(:classification, annotations: nil)).to_not be_valid
  end

  it "must have a state value" do
    expect(build(:classification, state: nil)).to_not be_valid
  end

  it "should be valid without a user" do
    expect(build(:classification, user: nil)).to be_valid
  end

  it 'should not be valid if incomplete with no user' do
    classification = build(:classification, user: nil, state: :incomplete)
    expect(classification).to_not be_valid
  end
  
  it 'should not be valid if enqueued with no user' do
    classification = build(:classification, user: nil, state: :enqueue)
    expect(classification).to_not be_valid
  end

  describe "::visible_to" do
    let(:user) { LoggedInUser.new(create(:user)) }
    let(:project) { create(:project, owner: user.owner) }
    let(:user_group) { create(:user_group) }
    let!(:classifications) do
      create(:membership, roles: ['group_admin'], user: user.owner,
             user_group: user_group, state: :active)
      [create(:classification, user: user.owner),
       create(:classification, project: project),
       create(:classification, user_group: user_group),
       create(:classification)]
    end

    it 'should return an ActiveRecord::Relation' do
      expect(Classification.visible_to(user)).to be_a(ActiveRecord::Relation)
    end

    it 'should return all classifications for a project if the user can updateit' do
      expected = classifications[1]
      expect(Classification.visible_to(user)).to include(expected)
    end

    it 'should return all classifications for a user group if the user can update it' do
      expected = classifications[2]
      expect(Classification.visible_to(user)).to include(expected)
    end

    it 'should return all classifications a user has made' do
      expected = classifications[0]
      expect(Classification.visible_to(user)).to include(expected)
    end

    it 'should all classifications for an admin' do
      admin_double = double({ is_admin?: true })
      expect(Classification.visible_to(admin_double, as_admin: true))
        .to match_array(classifications)
    end
  end

  describe "#creator?" do
    let(:user) { LoggedInUser.new(build(:user)) }

    it "should be truthy if a user is the classification's creator" do
      classification = build(:classification, user: user.owner)
      expect(classification.creator?(user)).to be_truthy
    end

    it "should be falsy if a user is not the classificaiton' creator" do
      classification = build(:classification)
      expect(classification.creator?(user)).to be_falsy
    end
  end

  describe "#incomplete?" do
    it "should be truthy if state attribute is completed" do
      expect(build(:classification, state: :incomplete).incomplete?).to be_truthy
    end

    it "should be falsy if completed attribute is true" do
      expect(build(:classification, state: :complete).incomplete?).to be_falsy
    end
  end

  describe "#in_show_scope?" do
    let(:user) { LoggedInUser.new(create(:user)) }

    it "should be truthy if the classification is in the actor's visible_scope" do
      classification = create(:classification, user: user.owner)
      expect(classification.in_show_scope?(user)).to be_truthy

    end

    it "should be falsy if the classification is not in the actor's visible_scope" do
      classification = create(:classification)
      expect(classification.in_show_scope?(user)).to be_falsy
    end

  end

  describe "#user_groups" do
    let(:expected_user_group) { create(:user_group) }
    let(:classification_with_user_group) { create(:classifaction_with_user_group, user_group: expected_user_group) }

    it "should a single user_group" do
      expect(classification_with_user_group.user_group).to eq(expected_user_group)
    end
  end

  describe "#enqueue_subject" do
    it 'should call enqueue_subject_for_user' do
      classification = build(:classification, state: :enqueue)
      expect(UserEnqueuedSubject).to receive(:enqueue_subject_for_user)
        .with(user: classification.user,
              workflow: classification.workflow,
              subject_id: classification.set_member_subject.id)
      classification.enqueue_subject
    end

    it 'should not call enqueue when there is no user' do
      classification = build(:classification, state: :enqueue, user: nil)
      expect(UserEnqueuedSubject).to_not receive(:enqueue_subject_for_user)
      classification.enqueue_subject
    end

    it 'should not call enqueue when the classification is in another state' do
      classification = build(:classification, state: :complete)
      expect(UserEnqueuedSubject).to_not receive(:enqueue_subject_for_user)
      classification.enqueue_subject
    end
  end
  
  describe "#dequeue_subject" do
    it 'should call dequeue_subject_for_user' do
      classification = create(:classification, state: :enqueue)
      expect(UserEnqueuedSubject).to receive(:dequeue_subject_for_user)
        .with(user: classification.user,
              workflow: classification.workflow,
              subject_id: classification.set_member_subject.id)
      classification.state = :complete
      classification.save!
    end

    it 'should not call dequeue_subject_for_user when state is not complete' do
      classification = create(:classification, state: :enqueue)
      expect(UserEnqueuedSubject).to_not receive(:dequeue_subject_for_user)
      classification.save!
    end

    it 'should not call dequeue_subject_for_use when state was :incomplete' do
      classification = create(:classification, state: :incomplete)
      expect(UserEnqueuedSubject).to_not receive(:dequeue_subject_for_user)
      classification.state = :complete
      classification.save!
    end
  end
end
