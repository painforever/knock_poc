class MeetingsController < ApplicationController
  before_action :set_knocker_knockee_meeting, except: [:create]
  def index
    @knockee_meetings = Meeting.where(knockee_id: current_user.id)
    @knocker_meetings = Meeting.where(knocker_id: current_user.id)

    binding.pry
    @meetings = Meeting.all()
  end

  def create
  	#TODO I need devise integration finished to finish meeting creation.
  	@meeting = Meeting.new(meeting_params)

    #now we need to assign some info that needs to be get from other models that can't get
    #directly from the form
    @knockee = User.find(meeting_params[:knockee_id])
    knocker = User.find(meeting_params[:knocker_id])
    @meeting.meeting_price = @knockee.phone_call_price

    #only if the meeting saved, then schedule the call if its type is 'call'
    if @meeting.save
      MeetingSetupMailer.new_call_mail_knockee(knocker, @knockee, @meeting).deliver_now
      MeetingSetupMailer.new_call_mail_knocker(knocker, @knockee, @meeting).deliver_now
    end
  end

  #basically all below actions need to pass 3 params by the URL queries, which is by GET or POST method:
  #1, knocker_id
  #2, knockee_id
  #3, meeting_id
  def accept_call
    @meeting.update_column('status', 1)
    time_to_call = Time.zone.parse("#{@meeting.meeting_time} -0400") - Time.zone.now
    MeetingSetupJob.set(wait: time_to_call.seconds).
        perform_later("+1#{@knockee.cell_phone}",
                      "+1#{@knocker.cell_phone}", @meeting.id) if @meeting.meeting_type == Constants::CALL_TYPE

    MeetingSetupMailer.accept_call_for_knocker_confirmation(@knocker, @knockee, @meeting).deliver_now
    MeetingSetupMailer.accept_call_for_knockee_confirmation(@knocker, @knockee, @meeting).deliver_now
  end


  def alternative_time
    #only if the form_action is present, then we do the action that needed, same as in reject_reason
    if params[:form_action]
      @meeting.update_column('reschedule_time', params[:reschedule_time])
      MeetingSetupMailer.alternative_call_for_knocker(@knocker, @knockee, @meeting, params[:alternative_time]).deliver_now
      redirect_to alternative_time_confirm_meetings_path
    end
  end

  def reject_reason
    if params[:form_action]
      @meeting.update_column('status', 2)
      @meeting.update_column('reject_reasons', params[:reject_reasons])
      MeetingSetupMailer.reject_call_for_knocker_confirmation(@knocker, @knockee, @meeting, params[:reject_reasons]).deliver_now
      MeetingSetupMailer.reject_call_for_knockee_confirmation(@knocker, @knockee, @meeting).deliver_now
      redirect_to reject_call_meetings_path
    end
  end

  private 
  #TODO we may need bunch of ***_params for every record creation based on strong parameters, may need 
  #to create a generic method to handle strong parameters
  def meeting_params
    params.require(:meeting).permit!
  end

  #like mentioned above, here to make sure all 3 params are present
  # in other words, @knocker, @knockee and @meeting must be present in those actions
  def set_knocker_knockee_meeting
    if params[:meeting_id].present? && params[:knockee_id].present? && params[:knocker_id].present?
      @knocker = User.find(params[:knocker_id])
      @knockee = User.find(params[:knockee_id])
      @meeting = Meeting.find(params[:meeting_id])
    end
  end
end
