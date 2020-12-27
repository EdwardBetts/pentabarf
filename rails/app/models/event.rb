class Event < Momomoto::Table
  SubmissionFields = [:title,:subtitle,:paper,:slides,:language,:licence,:conference_track_id,:event_type,:abstract,:description,:resources,:duration,:submission_notes,:presentation_length]

  module Methods

    def persons( *args )
      event_person( *args )
    end

  end

  def self.log_content_columns
    columns.keys - [:event_id]
  end

  def self.log_change_url( change )
    {:controller=>'event',:action=>:edit,:event_id=>change.event_id}
  end

  def self.log_change_title( change )
    conf = Conference.select_single(:conference_id=>change.conference_id)
    "#{conf.acronym}: #{change.title}"
   rescue
    change.title
  end

end
