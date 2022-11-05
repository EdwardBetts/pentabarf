class SubmissionController < ApplicationController

  before_filter :init

  def index
    @conferences = Conference.select({:f_submission_enabled=>true,:f_submission_writable=>true})
  end

  def login
    redirect_to(:action=>:index,:id=>'auth')
  end

  def event
    if params[:id] && params[:id] != 'new'
      own = Own_conference_events.call({:person_id=>POPE.user.person_id,:conference_id=>@conference.conference_id},{:own_conference_events=>params[:id]})
      raise "You are not allowed to edit this event." if (own.length != 1 && !POPE.conference_permission?( 'account_conference_role::create', @current_conference.conference_id))

      @event = Event.select_single({:event_id=>params[:id]})
    else
      raise "Submission of events has been disabled for this conference." if !@current_conference.f_submission_new_events
      @event = Event.new({:conference_id=>@conference.conference_id,:event_id=>0})
    end
    @attachments = View_event_attachment.select({:event_id=>@event.event_id,:translated=>@current_language})
  end

  def events
    own_events = Own_conference_events.call(:conference_id=>@conference.conference_id,:person_id=>POPE.user.person_id)
    own_events = own_events.map{|e| e.own_conference_events }
    if own_events.length > 0
      @events = View_event_person.select(:event_id=>own_events,:translated=>@current_language,:conference_id=>@conference.conference_id,:person_id=>POPE.user.person_id)
    else
      @events = []
    end
  end

  def save_event
    raise "Event title is mandatory" if params[:event][:title].empty?
    if params[:id].to_i == 0
      raise "Submission of events has been disabled for this conference." if !@current_conference.f_submission_new_events
      event = Submit_event.call(:e_person_id=>POPE.user.person_id,:e_conference_id=>@conference.conference_id,:e_title=>params[:event][:title])
      params[:id] = event[0].submit_event
      POPE.refresh
    end
    params[:event][:event_id] = params[:id]
    event = write_row( Event, params[:event], {:except=>[:event_id],:only=>Event::SubmissionFields,:always=>Event::SubmissionAlwaysFields} )
    custom_bools = Custom_fields.select({:table_name=>:event,:field_type=>:boolean,:submission_visible=>true,:submission_settable=>true}).map(&:field_name)
    custom_allowed = Custom_fields.select({:table_name=>:event,:submission_visible=>true,:submission_settable=>true}).map(&:field_name)
    write_row( Custom_event, params[:custom_event], {:preset=>{:event_id=>event.event_id},:always=>custom_bools,:only=>custom_allowed})
    write_rows( Event_link, params[:event_link], {:preset=>{:event_id => event.event_id},:ignore_empty=>:url})
    write_file_row( Event_image, params[:event_image], {:preset=>{:event_id => event.event_id},:image=>true})
    write_rows( Event_attachment, params[:event_attachment], {:always=>[:public]} )
    write_file_rows( Event_attachment, params[:attachment_upload], {:preset=>{:event_id=>event.event_id}})

    redirect_to( :action => :event, :id => event.event_id )
  end

  def person
    @person = Person.select_single(:person_id=>POPE.user.person_id)
    @account = Account.select_or_new(:person_id=>@person.person_id)
    @conference_person = Conference_person.select_or_new({:conference_id=>@conference.conference_id, :person_id=>@person.person_id})
    @conference_person_travel = Conference_person_travel.select_or_new({:conference_person_id=>@conference_person.conference_person_id.to_i})
    @person_image = Person_image.select_or_new({:person_id=>@person.person_id})
  end

  def save_person
    params[:person][:person_id] = POPE.user.person_id
    person = write_row( Person, params[:person], {:except=>[:person_id],:always=>[:spam]} )
    params[:account] ||= {}
    params[:account][:account_id] = Account.select_single(:person_id=>person.person_id).account_id rescue nil
    account = write_row( Account, params[:account], {:only=>[:current_language],:preset=>{:person_id=>person.person_id}} ) do | row |
      if params[:account][:password].to_s != ""
        raise "Passwords do not match" if params[:account][:password] != params[:account][:password2]
        row.password = params[:account][:password]
      end
    end
    write_row( Account_settings, params[:account_settings], {:preset=>{:account_id=>account.account_id}})
    options = {:preset=>{:person_id => person.person_id,:conference_id=>@conference.conference_id}}
    options[ @conference.f_reconfirmation_enabled ? :always : :except ] = [:reconfirmed]
    params[:conference_person] ||= {}
    conference_person = write_row( Conference_person, params[:conference_person], options )
    POPE.refresh if not POPE.own_conference_person?( conference_person.conference_person_id )
    custom_bools = Custom_fields.select({:table_name=>:person,:field_type=>:boolean,:submission_visible=>true,:submission_settable=>true}).map(&:field_name)
    custom_allowed = Custom_fields.select({:table_name=>:person,:submission_visible=>true,:submission_settable=>true}).map(&:field_name)
    write_row( Custom_person, params[:custom_person], {:preset=>{:person_id=>person.person_id},:always=>custom_bools,:only=>custom_allowed})
    custom_bools = Custom_fields.select({:table_name=>:conference_person,:field_type=>:boolean,:submission_visible=>true,:submission_settable=>true}).map(&:field_name)
    custom_allowed = Custom_fields.select({:table_name=>:conference_person,:submission_visible=>true,:submission_settable=>true}).map(&:field_name)
    write_row( Custom_conference_person, params[:custom_conference_person], {:preset=>{:person_id=>person.person_id,:conference_id=>conference_person.conference_id},:always=>custom_bools,:only=>custom_allowed})
    write_row( Conference_person_travel, params[:conference_person_travel], {:preset=>{:conference_person_id => conference_person.conference_person_id},:always=>[:need_travel_cost,:need_accommodation,:need_accommodation_cost,:arrival_pickup,:departure_pickup]}) if @conference.f_travel_enabled
    write_rows( Person_language, params[:person_language], {:preset=>{:person_id => person.person_id}})
    write_rows( Conference_person_link, params[:conference_person_link], {:preset=>{:conference_person_id => conference_person.conference_person_id},:ignore_empty=>:url})
    write_rows( Person_im, params[:person_im], {:preset=>{:person_id => person.person_id},:ignore_empty=>:im_address})
    write_rows( Person_phone, params[:person_phone], {:preset=>{:person_id => person.person_id},:ignore_empty=>:phone_number})

    write_file_row( Person_image, params[:person_image], {:preset=>{:person_id => person.person_id},:always=>[:public],:image=>true})
    write_person_availability( @conference, person, params[:person_availability])

    redirect_to( :action => :person )
  end

  protected

  def init
    @current_language = POPE.user ? POPE.user.current_language : 'en'
    begin
      constraints = {:acronym=>params[:conference],:f_submission_enabled=>true}
      constraints[:f_submission_writable] = true if params[:action].match(/^(save|delete)_/)
      @conference = Conference.select_single( constraints )
    rescue Momomoto::Error
      if params[:action] != 'index' || params[:conference]
        redirect_to(:controller=>'submission', :action => :index, :conference => nil )
        return false
      end
    end
    @current_conference = @conference
  end

  def auth
    return super if params[:action] != 'index' || params[:id] == 'auth'
    true
  end

  def check_permission
    POPE.permission?('submission::login') || render(:text=>'You are lacking permissions to login to the submission system. The most likely cause for this is your account has not yet been activated.')
  end

end
