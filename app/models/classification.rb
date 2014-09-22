class Classification < ActiveRecord::Base
  extend ControlControl::Resource
  include RoleControl::Adminable

  belongs_to :set_member_subject, counter_cache: true
  belongs_to :project, counter_cache: true
  belongs_to :user, counter_cache: true
  belongs_to :workflow, counter_cache: true
  belongs_to :user_group, counter_cache: true

  validates_presence_of :set_member_subject, :project, :workflow,
    :annotations, :user_ip, :state

  validates :user, presence: true, if: :incomplete?
  validates :user, presence: true, if: :enqueue?

  attr_accessible :user_id, :project_id, :workflow_id, :user_group_id,
    :set_member_subject_id, :annotations, :user_ip

  enum state: [:complete, :incomplete, :enqueue]

  can :show, :in_show_scope?
  can :update, :created_and_incomplete?
  can :destroy, :created_and_incomplete?

  after_create :enqueue_subject
  after_save :dequeue_subject

  def self.visible_to(actor, as_admin: false)
    ClassificationVisibilityQuery.new(actor, self).build(as_admin)
  end

  def creator?(actor)
    user == actor.user
  end

  def in_show_scope?(actor)
    self.class.visible_to(actor).exists?(self)
  end

  def enqueue_subject
    return true unless !!user && enqueue?
    UserEnqueuedSubject.enqueue_subject_for_user(user: user,
                                                 workflow: workflow,
                                                 subject_id: set_member_subject.id)
  end

  def dequeue_subject
    return true unless !!user && complete? && was_enqueued?
    UserEnqueuedSubject.dequeue_subject_for_user(user: user,
                                                 workflow: workflow,
                                                 subject_id: set_member_subject.id)
  end
  
  private

  def was_enqueued?
    changes[:state].try(:first) == "enqueue"
  end
  
  def created_and_incomplete?(actor)
    creator?(actor) && (incomplete? || enqueue?)
  end

end
