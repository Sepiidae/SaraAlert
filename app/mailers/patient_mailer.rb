# frozen_string_literal: true

# PatientMailer: mailers for monitorees
class PatientMailer < ApplicationMailer
  default from: 'notifications@saraalert.org'

  def enrollment_email(patient)
    # Should not be sending enrollment email if no valid email or this patient is not a responder
    return if patient&.email.blank? || patient.id != patient.responder_id

    # Gather patients and jurisdictions
    @patients = ([patient] + patient.dependents.where(monitoring: true)).uniq.collect do |p|
      { patient: p, jurisdiction_unique_id: Jurisdiction.find_by_id(p.jurisdiction_id).unique_identifier }
    end
    @lang = patient.select_language
    mail(to: patient.email&.strip, subject: I18n.t('assessments.email.enrollment.subject', locale: @lang)) do |format|
      format.html { render layout: 'main_mailer' }
    end
    History.welcome_message_sent(patient: patient)
  end

  def enrollment_sms_weblink(patient)
    # Should not be sending enrollment sms if no valid number or this patient is not a responder
    return if patient&.primary_telephone.blank? || patient.id != patient.responder_id

    lang = patient.select_language
    patient_name = "#{patient&.first_name&.first || ''}#{patient&.last_name&.first || ''}-#{patient&.calc_current_age || '0'}"
    intro_contents = "#{I18n.t('assessments.sms.weblink.intro1', locale: lang)} #{patient_name} #{I18n.t('assessments.sms.weblink.intro2', locale: lang)}"
    url_contents = new_patient_assessment_jurisdiction_report_lang_url(patient.submission_token,
                                                                       lang&.to_s || 'en',
                                                                       patient.jurisdiction.unique_identifier[0, 32])
    TwilioSender.send_sms(patient, intro_contents)
    TwilioSender.send_sms(patient, url_contents)
  end

  def enrollment_sms_text_based(patient)
    # Should not be sending enrollment sms if no valid number or this patient is not a responder
    return if patient&.primary_telephone.blank? || patient.id != patient.responder_id

    lang = patient.select_language
    patient_name = "#{patient&.first_name&.first || ''}#{patient&.last_name&.first || ''}-#{patient&.calc_current_age || '0'}"
    contents = "#{I18n.t('assessments.sms.prompt.intro1', locale: lang)} #{patient_name} #{I18n.t('assessments.sms.prompt.intro2', locale: lang)}"

    TwilioSender.send_sms(patient, contents)
  end

  # Right now the wording of this message is the same as for enrollment
  def assessment_sms_weblink(patient)
    add_fail_history_blank_field(patient, 'primary phone number') && return if patient&.primary_telephone.blank?

    num = patient.primary_telephone
    ([patient] + patient.dependents.where(monitoring: true)).uniq.each do |p|
      lang = p.select_language
      patient_name = "#{p&.first_name&.first || ''}#{p&.last_name&.first || ''}-#{p&.calc_current_age || '0'}"
      intro_contents = "#{I18n.t('assessments.sms.weblink.intro1', locale: lang)} #{patient_name} #{I18n.t('assessments.sms.weblink.intro2', locale: lang)}"
      url_contents = new_patient_assessment_jurisdiction_report_lang_url(p.submission_token,
                                                                         lang&.to_s || 'en',
                                                                         patient.jurisdiction.unique_identifier[0, 32])
      success = TwilioSender.send_sms(patient, intro_contents)
      success = sucsess && TwilioSender.send_sms(patient, url_contents)

      add_success_history(p, patient) if success
      add_fail_history_sms(patient) unless success
    end
    patient.update(last_assessment_reminder_sent: DateTime.now)

  end

  def assessment_sms_reminder(patient)
    add_fail_history_blank_field(patient, 'primary phone number') && return if patient&.primary_telephone.blank?

    lang = patient.select_language
    contents = I18n.t('assessments.sms.prompt.reminder', locale: lang)
    add_success_history(patient, patient) if TwilioSender.send_sms(patient, contents)

    # Always update the last contact time so the system does not try and send emails again.
    patient.update(last_assessment_reminder_sent: DateTime.now)
  end

  def assessment_sms(patient)
    add_fail_history_blank_field(patient, 'primary phone number') && return if patient&.primary_telephone.blank?

    lang = patient.select_language
    patient_names = ([patient] + patient.dependents.where(monitoring: true)).uniq.collect do |p|
      "#{p&.first_name&.first || ''}#{p&.last_name&.first || ''}-#{p&.calc_current_age || '0'}"
    end
    contents = I18n.t('assessments.sms.prompt.daily1', locale: lang) + patient_names.join(', ') + '.'

    # Prepare text asking about anyone in the group
    contents += if ([patient] + patient.dependents.where(monitoring: true)).uniq.count > 1
                  I18n.t('assessments.sms.prompt.daily2-p', locale: lang)
                else
                  I18n.t('assessments.sms.prompt.daily2-s', locale: lang)
                end

    # This assumes that all of the dependents will be in the same jurisdiction and therefore have the same symptom questions
    # If the dependets are in a different jurisdiction they may end up with too many or too few symptoms in their response
    contents += I18n.t('assessments.sms.prompt.daily3', locale: lang) + patient.jurisdiction.hierarchical_condition_bool_symptoms_string(lang) + '.'
    contents += I18n.t('assessments.sms.prompt.daily4', locale: lang)
    threshold_hash = patient.jurisdiction.jurisdiction_path_threshold_hash
    # The medium parameter will either be SMS or VOICE
    params = { prompt: contents, patient_submission_token: patient.submission_token,
               threshold_hash: threshold_hash, medium: 'SMS', language: lang.to_s.split('-').first.upcase,
               try_again: I18n.t('assessments.sms.prompt.try-again', locale: lang),
               thanks: I18n.t('assessments.sms.prompt.thanks', locale: lang) }

    if TwilioSender.start_studio_flow(patient, params)
      add_success_history(patient, patient)
    else
      add_fail_history_sms(patient)
    end

    # Always update the last contact time so the system does not try and send emails again.
    patient.update(last_assessment_reminder_sent: DateTime.now)

  end

  def assessment_voice(patient)
    add_fail_history_blank_field(patient, 'primary phone number') && return if patient&.primary_telephone.blank?

    lang = patient.select_language
    lang = :en if %i[so].include?(lang) # Some languages are not supported via voice
    patient_names = ([patient] + patient.dependents.where(monitoring: true)).uniq.collect do |p|
      "#{p&.first_name&.first || ''}, #{p&.last_name&.first || ''}, #{I18n.t('assessments.phone.age', locale: lang)} #{p&.calc_current_age || '0'},"
    end
    contents = I18n.t('assessments.phone.daily1', locale: lang) + patient_names.join(', ')

    # Prepare text asking about anyone in the group
    contents += if ([patient] + patient.dependents.where(monitoring: true)).uniq.count > 1
                  I18n.t('assessments.phone.daily2-p', locale: lang)
                else
                  I18n.t('assessments.phone.daily2-s', locale: lang)
                end

    # This assumes that all of the dependents will be in the same jurisdiction and therefore have the same symptom questions
    # If the dependets are in a different jurisdiction they may end up with too many or too few symptoms in their response
    contents += I18n.t('assessments.phone.daily3', locale: lang) + patient.jurisdiction.hierarchical_condition_bool_symptoms_string(lang) + '?'
    contents += I18n.t('assessments.phone.daily4', locale: lang)

    threshold_hash = patient.jurisdiction.jurisdiction_path_threshold_hash
    # The medium parameter will either be SMS or VOICE
    params = { prompt: contents, patient_submission_token: patient.submission_token,
               threshold_hash: threshold_hash, medium: 'VOICE', language: lang.to_s.split('-').first.upcase,
               intro: I18n.t('assessments.phone.intro', locale: lang),
               try_again: I18n.t('assessments.phone.try-again', locale: lang),
               thanks: I18n.t('assessments.phone.thanks', locale: lang) }

    if TwilioSender.start_studio_flow(patient, params)
      add_success_history(patient, patient)
    else
      add_fail_history_sms(patient)
    end
    # Always update the last contact time so the system does not try and send emails again.
    patient.update(last_assessment_reminder_sent: DateTime.now)

  end

  def assessment_email(patient)
    add_fail_history_blank_field(patient, 'email') && return if patient&.email.blank?

    @lang = patient.select_language
    # Gather patients and jurisdictions
    @patients = ([patient] + patient.dependents.where(monitoring: true)).uniq.collect do |p|
      { patient: p, jurisdiction_unique_id: Jurisdiction.find_by_id(p.jurisdiction_id).unique_identifier }
    end
    mail(to: patient.email&.strip, subject: I18n.t('assessments.email.reminder.subject', locale: @lang || :en)) do |format|
      format.html { render layout: 'main_mailer' }
    end
    add_success_history(patient, patient)
    # Always update the last contact time so the system does not try and send emails again.
    patient.update(last_assessment_reminder_sent: DateTime.now)
  end

  def closed_email(patient)
    return if patient&.email.blank?

    @patient = patient
    @lang = patient.select_language
    mail(to: patient.email&.strip, subject: I18n.t('assessments.email.closed.subject', locale: @lang || :en)) do |format|
      format.html { render layout: 'main_mailer' }
    end
  end

  private

  def add_success_history(patient, parent)
    comment = if patient == parent
                "Sara Alert sent a report reminder to this monitoree via #{parent.preferred_contact_method}."
              else
                "Sara Alert sent a report reminder to this monitoree's HoH via #{parent.preferred_contact_method}."
              end
    History.report_reminder(patient: patient, comment: comment)
  end

  def add_fail_history_sms(patient)
    comment = "Sara Alert attempted to send an SMS to #{patient.primary_telephone}, but the message could not be delivered."
    History.report_reminder(patient: patient, comment: comment)
  end

  def add_fail_history_voice(patient)
    History.report_reminder(patient: patient, comment: "Sara Alert failed to call monitoree at #{patient.primary_telephone}.")
  end

  def add_fail_history_blank_field(patient, type)
    History.report_reminder(patient: patient,
                            comment: "Sara Alert could not send a report reminder to this monitoree via \
                                     #{patient.preferred_contact_method}, because the monitoree #{type} number was blank.")
  end
end
