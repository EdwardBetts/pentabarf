class PentabarfController < ApplicationController
  before_filter :authorize, :check_permission
  after_filter :save_preferences, :except => [:meditation, :activity]
  after_filter :compress

  def initialize
    @content_title ='@content_title'
  end

  def index
    @content_title ='Overview'
  end

  def find_conference
    @conferences = Momomoto::View_find_conference.find( {:search => params[:id]} )
    @content_title ='Find Conference'
  end

  def search_conference
    @conferences = Momomoto::View_find_conference.find( {:search => request.raw_post} )
    render(:partial => 'search_conference')
  end

  def find_event
    @content_title ='Find Event'
    @events = Momomoto::View_find_event.find( {:s_title => params[:id], :conference_id => @current_conference_id, :translated_id => @current_language_id} )
  end

  def search_event
    @events = Momomoto::View_find_event.find( {:s_title => request.raw_post, :conference_id => @current_conference_id, :translated_id => @current_language_id} )
    render(:partial => 'search_event')
  end

  def search_event_advanced
    conditions = transform_advanced_search_conditions( params[:search])
    conditions[:translated_id] = @current_language_id
    conditions[:conference_id] = @current_conference_id
    @events = Momomoto::View_find_event.find( conditions )
    render(:partial => 'search_event')
  end

  def search_person_advanced
    conditions = transform_advanced_search_conditions( params[:search])
    @persons = Momomoto::View_find_person.find( conditions )
    render(:partial => 'search_person')
  end


  def transform_advanced_search_conditions( search )
    conditions = {}
    search.each do | key, value |
      if conditions[value['type'].to_sym]
        if
          conditions[value['type'].to_sym].kind_of?(Array)
          conditions[value['type'].to_sym].push(value['value'])
        else
          old_value = conditions[value['type'].to_sym]
          conditions[value['type'].to_sym] = []
          conditions[value['type'].to_sym].push( old_value )
          conditions[value['type'].to_sym].push( value['value'])
        end
      else
        conditions[value['type'].to_sym] = value['value']
      end
    end
    conditions 
  end

  def find_person
    @content_title ='Find Person'
    @persons = Momomoto::View_find_person.find( {:search => params[:id]}, 50 )
  end

  def search_person
    @persons = Momomoto::View_find_person.find( {:search => request.raw_post} )
    render(:partial => 'search_person')
  end

  def recent_changes
    @content_title ='Recent Changes'
    @changes = Momomoto::View_recent_changes.find( {}, params[:id] || 25 )
  end

  def conference
    if params[:id]
      if params[:id] == 'new'
        @content_title ='New Conference'
        @conference = Momomoto::Conference.new_record
        @conference.conference_id = 0
      else
        @conference = Momomoto::Conference.find( {:conference_id => params[:id] } )
        if @conference.length != 1
          redirect_to(:action => :meditation)
          return
        end
        @content_title = @conference.title
      end
    else
      render( :template => 'meditation', :layout => false )
    end
  end

  def event
    if params[:id]
      if params[:id] == 'new'
        @content_title ='New Event'
        @event = Momomoto::Event.new_record
        @event.event_id = 0
        @event.conference_id = @current_conference_id
        @rating = Momomoto::Event_rating.new_record
      else
        @event = Momomoto::Event.find( {:event_id => params[:id] } )
        if @event.length != 1
          redirect_to(:action => :meditation)
          return
        end
        @rating = Momomoto::Event_rating.find({:event_id => params[:id], :person_id => @user.person_id})
        @rating.create if @rating.length != 1
        @content_title = @event.title
      end
      @conference = Momomoto::Conference.find( {:conference_id => @event.conference_id } )
    else
      render( :template => 'meditation', :layout => false )
    end
  end

  def person
    if params[:id]
      if params[:id] == 'new'
        @content_title ='New Person'
        @person = Momomoto::View_person.new_record()
        @person.person_id = 0
        @person.f_spam = 't'
        @conference_person = Momomoto::Conference_person.new_record()
        @conference_person.conference_person_id = 0
        @conference_person.conference_id = @current_conference_id
        @conference_person.person_id = 0
        @person_travel = Momomoto::Person_travel.new_record()
        @rating = Momomoto::Person_rating.new_record()
      else
        @person = Momomoto::View_person.find( {:person_id => params[:id]} )
        if @person.length != 1
          redirect_to(:action => :meditation)
          return
        end
        @content_title = @person.name
        @conference_person = Momomoto::Conference_person.find({:conference_id => @current_conference_id, :person_id => @person.person_id})
        if @conference_person.length != 1
          @conference_person.create
          @conference_person.conference_person_id = 0
          @conference_person.conference_id = @current_conference_id
          @conference_person.person_id = @person.person_id
        end
        @person_travel = Momomoto::Person_travel.find( {:person_id => params[:id],:conference_id => @current_conference_id} )
        @person_travel.create if @person_travel.length == 0
        @rating = Momomoto::Person_rating.find({:person_id => params[:id], :evaluator_id => @user.person_id})
        @rating.create if @rating.length != 1
      end
    else
      render( :template => 'meditation', :layout => false )
    end
  end

  def conflicts
    @content_title = 'Conflicts'
  end

  def reports
    @content_title ='Reports'
  end

  def activity
    render(:partial => 'activity')
  end

  def meditation
    render( :template => 'meditation', :layout => false )
  end

  def save_person
    if params[:id] == 'new'
      person = Momomoto::Person.new_record()
    else
      person = Momomoto::Person.find( {:person_id => params[:person_id]} )
    end
    if person.length == 1

      if params[:changed_when] != ''
        transaction = Momomoto::Person_transaction.find( {:person_id => person.person_id} )
        if transaction.length == 1 && transaction.changed_when != params[:changed_when]
          render_text('Outdated Data.')
          return
        end
      end
    
      modified = false
      person.begin

      begin
        if params[:person][:password].to_s != ''
          raise "Passwords do not match" if params[:person][:password] != params[:password]
        end
        
        params[:person].each do | key, value |
          next if key.to_sym == :preferences
          person[key]= value
        end
        person[:gender] = nil if params[:person]['gender'] == ""
        person[:f_spam] = 'f' unless params[:person]['f_spam']
        person.password= params[:person][:password]
        prefs = person.preferences
        prefs[:current_language_id] = params[:person][:preferences][:current_language_id].to_i
        person.preferences = prefs
        modified = true if person.write

        conference_person = Momomoto::Conference_person.new
        conference_person.select({:conference_person_id => params[:conference_person][:conference_person_id],:conference_id => params[:conference_person][:conference_id], :person_id => person.person_id})
        if conference_person.length != 1
          conference_person.create
          conference_person.person_id = person.person_id
        end
        params[:conference_person].each do | key, value |
          next if key.to_sym == :conference_person_id || key.to_sym == :person_id
          conference_person[key] = value
        end
        modified = true if conference_person.write
        
        image = Momomoto::Person_image.new
        image.select({:person_id => person.person_id})
        if image.length != 1 && params[:person_image][:image].size > 0
          image.create
          image.person_id = person.person_id
        end
        if image.length == 1
          image.f_public = ( params[:person_image] && params[:person_image][:f_public] ) ? 't' : 'f'
          if params[:person_image][:image].size > 0
            mime_type = Momomoto::Mime_type.find({:mime_type => params[:person_image][:image].content_type.chomp, :f_image => 't'})
            raise "mime-type not found #{params[:person_image][:image].content_type}" if mime_type.length != 1
            image.mime_type_id = mime_type.mime_type_id
            image.image = process_image( params[:person_image][:image].read )
            image.last_changed = 'now()'
          end
          modified = true if image.write
        end

        person_role = Momomoto::Person_role.new
        for role in Momomoto::Role.find()
          if params[:person_role] && params[:person_role][role.role_id.to_s]
            if person_role.select({:person_id => person.person_id, :role_id => role.role_id}) == 1
              next
            else
              person_role.create()
              person_role.person_id = person.person_id
              person_role.role_id = role.role_id
              modified = true if person_role.write
            end
          else
            if person_role.select({:person_id => person.person_id, :role_id => role.role_id}) == 0
              next
            elsif person_role.length == 1
              modified = true if person_role.delete
            else
              raise "multiple rows while handling roles"
            end
          end
        end

        person_travel = Momomoto::Person_travel.find( {:person_id => person.person_id, :conference_id => @current_conference_id} )
        if person_travel.length != 1
          person_travel.create
          person_travel.person_id = person.person_id
          person_travel.conference_id = @current_conference_id
        end

        params[:person_travel].each do | key, value |
          person_travel[key]= value
        end
        person_travel.f_arrived = 'f' unless params[:person_travel]['f_arrived']
        person_travel.f_arrival_pickup = 'f' unless params[:person_travel]['f_arrival_pickup']
        person_travel.f_departure_pickup = 'f' unless params[:person_travel]['f_departure_pickup']
        modified = true if person_travel.write

        rating = Momomoto::Person_rating.find( {:person_id => person.person_id, :evaluator_id => @user.person_id} )
        if rating.length != 1
          rating.create
          rating.person_id = person.person_id
          rating.evaluator_id = @user.person_id
        end

        params[:rating].each { | key, value | rating[key] = value }
        rating.eval_time = 'now()'
        modified = true if rating.write
        
        if params[:event_person]
          event = Momomoto::Event_person.new()
          params[:event_person].each do | key, value |
            event.select({:person_id => person.person_id, :event_person_id => value[:event_person_id]})
            if event.length != 1
              event.create
              event.person_id = person.person_id
            end

            if value[:delete]
              event.delete unless event.new_record
              next
            end

            value.each do | field_name, field_value |
              next if field_name.to_sym == :event_person_id
              event[field_name] = field_value
            end
            if event.write
              transaction = Momomoto::Event_transaction.new_record()
              transaction.event_id = event.event_id
              transaction.changed_by = @user.person_id
              transaction.write
              modified = true
            end
          end
        end
        
        if params[:person_im]
          person_im = Momomoto::Person_im.new()
          params[:person_im].each do | key, value |
            person_im.select( {:person_id => person.person_id, :person_im_id => value[:person_im_id]} )
            if person_im.length != 1
              person_im.create
              person_im.person_id = person.person_id
            end

            if value[:delete]
              person_im.delete unless person_im.new_record
              next
            end

            value.each do | field_name, field_value |
              next if field_name.to_sym == :person_im_id
              person_im[field_name]= field_value
            end
            modified = true if person_im.write
          end
        end

        if params[:person_phone]
          person_phone = Momomoto::Person_phone.new()
          params[:person_phone].each do | key, value |
            person_phone.select( {:person_id => person.person_id, :person_phone_id => value[:person_phone_id]})
            if person_phone.length != 1
              person_phone.create
              person_phone.person_id = person.person_id
            end

            if value[:delete]
              person_phone.delete unless person_phone.new_record
              next
            end

            value.each do | field_name, field_value |
              next if field_name.to_sym == :person_phone_id
              person_phone[field_name] = field_value
            end
            modified = true if person_phone.write
          end
        end

        if params[:link]
          person_link = Momomoto::Person_link.new()
          params[:link].each do | key, value |
            person_link.select( {:person_id => person.person_id, :person_link_id => value[:link_id]} )
            if person_link.length != 1
              person_link.create
              person_link.person_id = person.person_id
            end

            if value[:delete]
              person_link.delete unless person_link.new_record
              next
            end

            value.each do | field_name, field_value |
              next if field_name.to_sym == :link_id
              person_link[field_name] = field_value
            end
            modified = true if person_link.write
          end
        end

        if params[:internal_link]
          person_link_internal = Momomoto::Person_link_internal.new()
          params[:internal_link].each do | key, value |
            person_link_internal.select( {:person_id => person.person_id, :person_link_internal_id => value[:internal_link_id]} )
            if person_link_internal.length != 1
              person_link_internal.create
              person_link_internal.person_id = person.person_id
            end

            if value[:delete]
              person_link_internal.delete unless person_link_internal.new_record
              next
            end

            value.each do | field_name, field_value |
              next if field_name.to_sym == :internal_link_id
              person_link_internal[field_name] = field_value
            end
            modified = true if person_link_internal.write
          end
        end

        if modified == true
          transaction = Momomoto::Person_transaction.new_record()
          transaction.person_id = person.person_id
          transaction.changed_by = @user.person_id
          transaction.f_create = 't' if params[:id] == 'new'
          transaction.write
          person.commit
        else
          person.rollback
        end
      rescue => e
        person.rollback
        raise e
      end
      
      redirect_to({:action => :person, :id => person.person_id})
    end
  end

  def save_conference
    if params[:id] == 'new'
      conference = Momomoto::Conference.new_record()
    else
      conference = Momomoto::Conference.find( {:conference_id => params[:conference_id]})
    end
    if conference.length == 1
      if params[:changed_when] != ''
        transaction = Momomoto::Conference_transaction.find( {:conference_id => conference.conference_id} )
        if transaction.length == 1 && transaction.changed_when != params[:changed_when]
          render_text('Outdated Data.')
          return
        end
      end

      modified = false
      conference.begin

      begin
        params[:conference].each do | key, value |
          conference[key]= value
        end
        modified = true if conference.write

        image = Momomoto::Conference_image.new
        image.select({:conference_id => conference.conference_id})
        if image.length != 1 && params[:conference_image][:image].size > 0
          image.create
          image.conference_id = conference.conference_id
        end
        if image.length == 1
          if params[:conference_image][:image].size > 0
            mime_type = Momomoto::Mime_type.find({:mime_type => params[:conference_image][:image].content_type.chomp, :f_image => 't'})
            raise "mime-type not found #{params[:conference_image][:image].content_type}" if mime_type.length != 1
            image.mime_type_id = mime_type.mime_type_id
            image.image = process_image( params[:conference_image][:image].read )
            image.last_changed = 'now()'
          end
          modified = true if image.write
        end

        if params[:team]
          team = Momomoto::Team.new
          params[:team].each do | key, value |
            team.select({:conference_id => conference.conference_id, :team_id => value[:team_id]})
            if team.length != 1
              team.create
              team.conference_id = conference.conference_id
            end

            if value[:delete]
              team.delete unless team.new_record
              next
            end

            value.each do | field_name, field_value |
              next if field_name.to_sym == :team_id
              team[field_name] = field_value
            end
            modified = true if team.write
          end
        end

        if params[:conference_track]
          track = Momomoto::Conference_track.new
          params[:conference_track].each do | key, value |
            track.select({:conference_id => conference.conference_id, :conference_track_id => value[:conference_track_id]})
            if track.length != 1
              track.create
              track.conference_id = conference.conference_id
            end

            if value[:delete]
              team.delete unless team.new_record
              next
            end

            value.each do | field_name, field_value |
              next if field_name.to_sym == :conference_track_id
              track[field_name] = field_value
            end
            modified = true if track.write
          end
        end

        if params[:room]
          room = Momomoto::Room.new
          params[:room].each do | key, value |
            room.select({:conference_id => conference.conference_id, :room_id => value[:room_id]})
            if room.length != 1
              room.create
              room.conference_id = conference.conference_id
            end

            if value[:delete]
              room.delete unless room.new_record
              next
            end

            value.each do | field_name, field_value |
              next if field_name.to_sym == :room_id
              room[field_name] = field_value
            end
            modified = true if room.write
          end
        end

        if modified == true
          transaction = Momomoto::Conference_transaction.new_record()
          transaction.conference_id = conference.conference_id
          transaction.changed_by = @user.person_id
          transaction.f_create = 't' if params[:id] == 'new'
          transaction.write
          conference.commit
        else
          conference.rollback
        end
      rescue => e
        conference.rollback
        raise e
      end
      redirect_to({:action => :conference, :id => conference.conference_id})
    end
  end

  def save_event
    if params[:id] == 'new'
      event = Momomoto::Event.new_record()
    else
      event = Momomoto::Event.find( {:event_id => params[:event_id]} )
    end
    if event.length == 1

      if params[:changed_when] != ''
        transaction = Momomoto::Event_transaction.find( {:event_id => event.event_id} )
        if transaction.length == 1 && transaction.changed_when != params[:changed_when]
          render_text('Outdated Data.')
          return
        end
      end
    
      modified = false
      event.begin
      
      begin
        params[:event].each do | key, value |
          event[key]= value
        end
        event.f_public = 'f' unless params[:event]['f_public']
        event.f_paper = 'f' unless params[:event]['f_paper']
        event.f_slides = 'f' unless params[:event]['f_slides']
        modified = true if event.write

        rating = Momomoto::Event_rating.find( {:person_id => @user.person_id, :event_id => event.event_id} )
        if rating.length != 1
          rating.create
          rating.event_id = event.event_id
          rating.person_id = @user.person_id
        end

        params[:rating].each { | key, value | rating[key] = value }
        rating.eval_time = 'now()'
        modified = true if rating.write
        
        image = Momomoto::Event_image.new
        image.select({:event_id => event.event_id})
        if image.length != 1 && params[:event_image][:image].size > 0
          image.create
          image.event_id = event.event_id
        end
        if image.length == 1
          if params[:event_image][:image].size > 0
            mime_type = Momomoto::Mime_type.find({:mime_type => params[:event_image][:image].content_type.chomp, :f_image => 't'})
            raise "mime-type not found #{params[:event_image][:image].content_type}" if mime_type.length != 1
            image.mime_type_id = mime_type.mime_type_id
            image.image = process_image( params[:event_image][:image].read )
            image.last_changed = 'now()'
          end
          modified = true if image.write
        end

        if params[:event_person]
          person = Momomoto::Event_person.new()
          params[:event_person].each do | key, value |
            person.select({:event_id => event.event_id, :event_person_id => value[:event_person_id]})
            if person.length != 1
              person.create
              person.event_id = event.event_id
            end

            if value[:delete]
              person.delete unless person.new_record
              next
            end

            value.each do | field_name, field_value |
              next if field_name.to_sym == :event_person_id
              person[field_name] = field_value
            end

            if person.write
              transaction = Momomoto::Person_transaction.new_record()
              transaction.person_id = person.person_id
              transaction.changed_by = @user.person_id
              transaction.write
              modified = true
            end
          end
        end
        
        if params[:link]
          event_link = Momomoto::Event_link.new()
          params[:link].each do | key, value |
            event_link.select( {:event_id => event.event_id, :event_link_id => value[:link_id]} )
            if event_link.length != 1
              event_link.create
              event_link.event_id = event.event_id
            end

            if value[:delete]
              event_link.delete unless event_link.new_record
              next
            end

            value.each do | field_name, field_value |
              next if field_name.to_sym == :link_id
              event_link[field_name] = field_value
            end
            modified = true if event_link.write
          end
        end

        if params[:internal_link]
          event_link_internal = Momomoto::Event_link_internal.new()
          params[:internal_link].each do | key, value |
            event_link_internal.select( {:event_id => event.event_id, :event_link_internal_id => value[:internal_link_id]} )
            if event_link_internal.length != 1
              event_link_internal.create
              event_link_internal.event_id = event.event_id
            end

            if value[:delete]
              event_link_internal.delete unless event_link_internal.new_record
              next
            end

            value.each do | field_name, field_value |
              next if field_name.to_sym == :internal_link_id
              event_link_internal[field_name] = field_value
            end
            modified = true if event_link_internal.write
          end
        end

        if modified == true
          transaction = Momomoto::Event_transaction.new_record()
          transaction.event_id = event.event_id
          transaction.changed_by = @user.person_id
          transaction.f_create = 't' if params[:id] == 'new'
          transaction.write
          event.commit
        else
          event.rollback
        end
      rescue => e
        event.rollback
        raise e
      end
      redirect_to({:action => :event, :id => event.event_id})
    end
  end

  protected

  def check_permission
    #redirect_to :action => :meditation if params[:action] != 'meditation'
    if @user.permission?('login_allowed') || params[:action] == 'meditation'
      @preferences = @user.preferences
      if params[:current_conference_id]
        conf = Momomoto::Conference.find({:conference_id => params[:current_conference_id]})
        if conf.length == 1
          @preferences[:current_conference_id] = params[:current_conference_id].to_i
          @user.preferences = @preferences
          @user.write
          redirect_to()
          return false
        end
      end
      @current_conference_id = @preferences[:current_conference_id]
      @current_language_id = @preferences[:current_language_id]
    else
      redirect_to( :action => :meditation )
      false
    end
  end

  def process_image( image )
    image
  end

end
