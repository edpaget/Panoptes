require 'benchmark'

class PostgresqlSelection
  attr_reader :workflow, :user, :opts

  def initialize(workflow, user=nil)
    @workflow, @user = workflow, user
  end

  def select(options={})
    @opts = options
    results = case selection_strategy
              when :in_order
                select_results_in_order
              else
                select_results_randomly
              end
    results.take(limit)
  end

  private

  def available
    return @available if @available
    query = SetMemberSubject.available(workflow, user)
    if workflow.grouped
      query = query.where(subject_set_id: opts[:subject_set_id])
    end
    if workflow.prioritized
      query = query.order(priority: :asc)
    end
    @available = query
  end

  def available_count
    @available_count ||= available.except(:select).count
  end

  def sample(query=available)
    direction = [ :asc, :desc ].sample
    offset = ((available_count - limit) * rand).to_i

    #p query.order(random: direction).offset(offset).explain
    p query.where("random > ?", rand).order(random: direction).offset(offset).explain
    #p SetMemberSubject.order(random: direction).explain
    #SetMemberSubject.order(random: direction)
    #query.order("RANDOM() #{direction}")
  end

  def limit
    @limit ||= opts.fetch(:limit, 20).to_i
  end

  def selection_strategy
    if workflow.prioritized
      :in_order
    else
      :other
    end
  end

  def select_results_randomly
    enough_available = limit < available_count
    if enough_available
      Benchmark.bm do |x|
        x.report { sample.limit(limit).pluck(:id) }
      end
    else
      available.pluck(:id).shuffle
    end
  end

  def select_results_in_order
    available.limit(limit).pluck(:id)
  end
end
