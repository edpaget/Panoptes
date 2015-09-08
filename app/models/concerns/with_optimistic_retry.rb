# http://apidock.com/rails/ActiveRecord/Persistence/reload
module WithOptimisticRetry

  private

  def with_optimistic_retry(retries=nil)
    retries ||= 10
    begin
      yield
    rescue ActiveRecord::StaleObjectError => e
      reload
      retries -= 1
      if retries > 0
        retry
      else
        raise e
      end
    end
  end
end
