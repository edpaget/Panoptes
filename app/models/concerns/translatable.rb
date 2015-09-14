module Translatable
  extend ActiveSupport::Concern

  included do
    validates :primary_language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}
    has_many content_association, autosave: true, inverse_of: name.downcase.to_sym
    can_be_linked content_model.name.underscore.to_sym, :scope_for, :translate, :user

    validates content_association, presence: true
  end

  module ClassMethods
    def content_association
      "#{model_name.singular}_contents".to_sym
    end

    def content_model
      "#{name}Content".constantize
    end
  end

  def content_for(languages)
    #query = content_association.where(language: primary_language)

    #if languages
      #lang_search = languages.map{ |lang| lang[0..1] + '%' }.uniq
      #or_matches = content_association.where("language ILIKE any (array[?])", lang_search)
      #query = query.or(or_matches)
    #end
    #lang_array = "array[#{languages.map{ |l| "'" + l + "'" }.join(',')}]"
    #query.order("array_search('en', #{lang_array})").first
    languages_to_sort = (languages + [primary_language]).flat_map do |l|
      if l.length == 2
        l
      else
        [l, l[0..1]]
      end
    end.uniq

    p languages_to_sort

    content_association.select{ |ca| languages_to_sort.include?(ca.language) }
      .sort { |ca| languages_to_sort.index_of?(ca.language) }.first
  end

  def available_languages
    content_association.pluck('language').map(&:downcase)
  end

  def content_association
    @content_association ||= send(self.class.content_association)
  end

  def primary_content
    @primary_content ||= if content_association.loaded?
                           content_association.to_a.find do |content|
                             content.language == primary_language
                           end
                         else
                           content_association.where(language: primary_language).first
                         end
  end
end
