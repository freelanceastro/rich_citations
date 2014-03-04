class Result < ActiveRecord::Base
  before_create :set_token
  before_save   :normalize_fields

  validates :query, presence:true
  validates :limit, presence:true, numericality: { only_integer:true, greater_than:0, less_than_or_equal_to:50 }

  def self.find_or_new(params)
    params[:query] = params[:query].try(:strip)

    find_params = params.dup
    find_params[:query] = find_params[:query].try(:downcase)

    self.where(find_params).first || self.new(params)
  end

  def self.for_token(token)
    self.where(token:token).first!
  end

  def start_analysis!
    if self.analysis_json.present?
      self.touch
    else
      #@mro - Start thread here
      analyze!
    end

  end

  def analysis_results
    @analysis_results ||= JSON.parse(analysis_json).with_indifferent_access
  end

  def matches
    analysis_results[:matches]
  end

  private

  def analyze!
    matching_dois = search_dois

    database = Plos::PaperDatabase.new

    matching_dois.each do |doi|
      paper = Paper.calculate_for(doi)
      database.add_paper(doi, paper.references)
    end
    Rails.logger.info("Completed Analysis")

    results = JSON.generate(database.results)
    update_attributes!(analysis_json:results)
  end

  def search_dois
    if self.query_result.blank?
      Rails.logger.info("Searching for #{self.query.inspect} (limit:#{self.limit}")
      matching = Plos::Api.search(self.query, query_type: "subject", rows: self.limit)
      self.update_attributes!(query_result: JSON.generate(matching))
      Rails.logger.info("Found #{matching.count} results")
    else
      matching = JSON.parse(self.query_result)
      Rails.logger.info("Using #{matching.count} cached query results")
    end

    matching.map { |r| r['id'] }
  end

  def set_token
    self.token = SecureRandom.urlsafe_base64(nil, false)
  end

  def normalize_fields
    self.query &&= self.query.downcase
  end

end
