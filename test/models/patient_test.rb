# frozen_string_literal: true

require 'test_case'

class PatientTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create patient' do
    assert create(:patient)
  end

  test 'monitoring open' do
    patient = create(:patient, monitoring: true, purged: false)
    assert_equal 1, Patient.monitoring_open.where(id: patient.id).count

    patient = create(:patient, monitoring: false, purged: false)
    assert_equal 0, Patient.monitoring_open.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: true)
    assert_equal 0, Patient.monitoring_open.where(id: patient.id).count

    patient = create(:patient, monitoring: false, purged: true)
    assert_equal 0, Patient.monitoring_open.where(id: patient.id).count
  end

  test 'monitoring closed' do
    patient = create(:patient, monitoring: false)
    assert_equal 1, Patient.monitoring_closed.where(id: patient.id).count

    patient = create(:patient, monitoring: true)
    assert_equal 0, Patient.monitoring_closed.where(id: patient.id).count
  end

  test 'monitoring closed without purged' do
    patient = create(:patient, monitoring: false, purged: false)
    assert_equal 1, Patient.monitoring_closed_without_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false)
    assert_equal 0, Patient.monitoring_closed_without_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: true)
    assert_equal 0, Patient.monitoring_closed_without_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: false, purged: true)
    assert_equal 0, Patient.monitoring_closed_without_purged.where(id: patient.id).count
  end

  test 'monitoring closed with purged' do
    patient = create(:patient, monitoring: false, purged: true)
    assert_equal 1, Patient.monitoring_closed_with_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false)
    assert_equal 0, Patient.monitoring_closed_with_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: true)
    assert_equal 0, Patient.monitoring_closed_with_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: false, purged: false)
    assert_equal 0, Patient.monitoring_closed_with_purged.where(id: patient.id).count
  end

  test 'purge eligible' do
    jur = Jurisdiction.create
    user = User.create!(
      email: 'foobar@example.com',
      password: '1234567ab!',
      jurisdiction: jur,
      force_password_change: true # Require user to change password on first login
    )
    Patient.destroy_all
    patient = Patient.new(creator: user, jurisdiction: jur)
    patient.responder = patient
    patient.save
    assert Patient.count == 1
    # Updated at of today, still monitoring, should not be purgeable
    assert Patient.purge_eligible.count.zero?
    patient.update!(monitoring: false)
    # Updated at of today, not monitoring, should not be purgeable
    assert Patient.purge_eligible.count.zero?
    # Updated at of 2x purgeable_after, not monitoring, should obviously be purgeable regardless of weekly_purge_date and weekly_purge_warning_date
    patient.update!(updated_at: (2 * ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert Patient.purge_eligible.count == 1
    # ADMIN_OPTIONS['weekly_purge_warning_date'] is 2.5 days before ADMIN_OPTIONS['weekly_purge_date']
    # Test if the email was going out in 1 minute and patient was updated purgeable_after minutes ago, patient should be purgeable
    # These tests reset the weekly_purge_warning_date and weekly_purge_date, and set the times to 1 minute from Time.now to avoid timing issues
    # caused by the duration of time it takes to run the test
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 2.5.days + 1.minute).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert Patient.purge_eligible.count == 1
    # However, if the test email was going out in 1 minute from now and the patient was last updated purgeable_after - 2 minutes ago, no purge
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 2.5.days + 1.minute).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after'] - 2).minutes.ago)
    assert Patient.purge_eligible.count.zero?
    # Now test the boundry conditions that exist between the purge_warning and the purging
    # ADMIN_OPTIONS['weekly_purge_warning_date'] is 2.5 days before ADMIN_OPTIONS['weekly_purge_date']
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute - 2.5.days).strftime('%A %l:%M%p')
    # If the email is going out in 1 minute, and the patient was modified purgeable_after minutes ago, they should not be purgeable
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert Patient.purge_eligible.count.zero?
    # However, if the email is going out in 1 minute and the patient was modified right before the warning (2.5 days ago), they should be purgeable
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute - 2.5.days).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after'] + (2.5.days / 1.minute)).minutes.ago)
    assert Patient.purge_eligible.count == 1
    # Anything less than the 2.5 days ago means the patient was modified between the warning and the purging and should not be purged
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute - 2.5.days).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after'] + (2.5.days / 1.minute) - 2).minutes.ago)
    assert Patient.purge_eligible.count.zero?
  end

  test 'purged' do
    patient = create(:patient, purged: false)
    assert_equal 0, Patient.purged.where(id: patient.id).count

    patient = create(:patient, purged: true)
    assert_equal 1, Patient.purged.where(id: patient.id).count
  end

  test 'confirmed case' do
    patient = create(:patient, monitoring_reason: 'Case confirmed')
    assert_equal 1, Patient.confirmed_case.where(id: patient.id).count

    patient = create(:patient, monitoring_reason: 'Completed Monitoring')
    assert_equal 0, Patient.confirmed_case.where(id: patient.id).count

    patient = create(:patient)
    assert_equal 0, Patient.confirmed_case.where(id: patient.id).count
  end

  test 'under investigation' do
    patient = create(:patient, monitoring: true, purged: false, isolation: false, public_health_action: 'Recommended laboratory testing')
    assert_equal 1, Patient.under_investigation.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, isolation: false, public_health_action: 'None')
    assert_equal 0, Patient.under_investigation.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, isolation: false)
    assert_equal 0, Patient.under_investigation.where(id: patient.id).count
  end

  test 'symptomatic' do
    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None')
    create(:assessment, patient: patient, symptomatic: true)
    assert_equal 1, Patient.symptomatic.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None')
    create(:assessment, patient: patient, symptomatic: false)
    assert_equal 0, Patient.symptomatic.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None')
    assert_equal 0, Patient.symptomatic.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'Recommended laboratory testing')
    create(:assessment, patient: patient, symptomatic: true)
    assert_equal 0, Patient.symptomatic.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 25.hours.ago)
    assert_equal 1, Patient.symptomatic.where(id: patient.id).count
  end

  test 'non reporting' do
    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    assert_equal 1, Patient.non_reporting.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None')
    assert_equal 0, Patient.non_reporting.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: false)
    assert_equal 0, Patient.non_reporting.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 25.hours.ago)
    assert_equal 1, Patient.non_reporting.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 25.hours.ago)
    assert_equal 0, Patient.non_reporting.where(id: patient.id).count
  end

  test 'asymptomatic' do
    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None')
    assert_equal 1, Patient.asymptomatic.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    assert_equal 0, Patient.asymptomatic.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: false)
    assert_equal 1, Patient.asymptomatic.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 25.hours.ago)
    assert_equal 0, Patient.asymptomatic.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 25.hours.ago)
    assert_equal 0, Patient.asymptomatic.where(id: patient.id).count
  end

  test 'test based' do
    # setup
    patient = create(:patient, monitoring: true, purged: false, isolation: true)
    assert_equal 0, Patient.test_based.where(id: patient.id).count

    # meets definition: has at least 1 assessment and 2 negative test results
    create(:assessment, patient: patient, created_at: 50.days.ago)
    create(:laboratory, patient: patient, result: 'negative', report: 50.days.ago)
    create(:laboratory, patient: patient, result: 'negative', report: 50.days.ago)
    assert_equal 1, Patient.test_based.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: no assessments
    create(:laboratory, patient: patient, result: 'negative')
    create(:laboratory, patient: patient, result: 'negative')
    assert_equal 0, Patient.test_based.where(id: patient.id).count
    Laboratory.destroy_all

    # does not meet definition: only 1 negative test result
    create(:assessment, patient: patient)
    create(:laboratory, patient: patient, result: 'negative')
    assert_equal 0, Patient.test_based.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all
  end

  test 'symp non test based' do
    # setup
    patient = create(:patient, monitoring: true, purged: false, isolation: true, symptom_onset: 12.days.ago)
    assert_equal 0, Patient.symp_non_test_based.where(id: patient.id).count

    # meets definition: assessment older than 72 hours
    create(:assessment, patient: patient, created_at: 80.hours.ago)
    assert_equal 1, Patient.symp_non_test_based.where(id: patient.id).count
    Assessment.destroy_all

    # does not meet definition: assessment not older than 72 hours
    create(:assessment, patient: patient, created_at: 70.hours.ago)
    assert_equal 0, Patient.symp_non_test_based.where(id: patient.id).count
    Assessment.destroy_all

    # does not meet definition: had a fever within the past 72 hours
    create(:assessment, patient: patient, created_at: 80.hours.ago)
    assessment_2 = create(:assessment, patient: patient, created_at: 70.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment_2)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'fever', bool_value: true)
    assert_equal 0, Patient.symp_non_test_based.where(id: patient.id).count
    Assessment.destroy_all

    # does not meet definition: used a fever reducer within the past 72 hours
    create(:assessment, patient: patient, created_at: 80.hours.ago)
    assessment_2 = create(:assessment, patient: patient, created_at: 70.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment_2)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'used-a-fever-reducer', bool_value: true)
    assert_equal 0, Patient.symp_non_test_based.where(id: patient.id).count
    Assessment.destroy_all

    # meets definition: had an assessment with no fever
    create(:assessment, patient: patient, created_at: 80.hours.ago)
    assessment_2 = create(:assessment, patient: patient, created_at: 70.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment_2)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'fever', bool_value: false)
    assert_equal 1, Patient.symp_non_test_based.where(id: patient.id).count
    Assessment.destroy_all

    # meets definition: had a fever more than 72 hours ago
    assessment = create(:assessment, patient: patient, created_at: 80.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'fever', bool_value: true)
    assert_equal 1, Patient.symp_non_test_based.where(id: patient.id).count
    Assessment.destroy_all
  end

  test 'asymp non test based' do
    # setup
    patient = create(:patient, monitoring: true, purged: false, isolation: true)
    assert_equal 0, Patient.asymp_non_test_based.where(id: patient.id).count

    # meets definition: asymptomatic after positive test result
    create(:laboratory, patient: patient, result: 'positive', report: 15.days.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 8.days.ago)
    assert_equal 1, Patient.asymp_non_test_based.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # meets definition: only symptomatic before positive test result but not afterwards
    create(:assessment, patient: patient, symptomatic: true, created_at: 12.days.ago)
    create(:laboratory, patient: patient, result: 'positive', report: 11.days.ago)
    assert_equal 1, Patient.asymp_non_test_based.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet defiition: has positive test result less than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', report: 8.days.ago)
    assert_equal 0, Patient.asymp_non_test_based.where(id: patient.id).count
    Laboratory.destroy_all

    # does not meet defiition: has positive test result more than 10 days ago, but also has positive test result less than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', report: 11.days.ago)
    create(:laboratory, patient: patient, result: 'positive', report: 9.days.ago)
    assert_equal 0, Patient.asymp_non_test_based.where(id: patient.id).count
    Laboratory.destroy_all

    # does not meet defiition: has negative test result more than 10 days ago, but also has positive test result less than 10 days ago
    create(:laboratory, patient: patient, result: 'negative', report: 11.days.ago)
    create(:laboratory, patient: patient, result: 'positive', report: 9.days.ago)
    assert_equal 0, Patient.asymp_non_test_based.where(id: patient.id).count
    Laboratory.destroy_all

    # does not meet defiition: has positive test result more than 10 days ago, but also has positive test result less than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', report: 11.days.ago)
    create(:laboratory, patient: patient, result: 'negative', report: 9.days.ago)
    assert_equal 0, Patient.asymp_non_test_based.where(id: patient.id).count
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result
    create(:laboratory, patient: patient, result: 'positive', report: 15.days.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 8.days.ago)
    assert_equal 0, Patient.asymp_non_test_based.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', report: 13.days.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 12.days.ago)
    assert_equal 0, Patient.asymp_non_test_based.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', report: 12.days.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 6.days.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 5.days.ago)
    create(:laboratory, patient: patient, result: 'negative', report: 3.days.ago)
    assert_equal 0, Patient.asymp_non_test_based.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', report: 15.days.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 14.days.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 13.days.ago)
    create(:laboratory, patient: patient, result: 'negative', report: 12.days.ago)
    assert_equal 0, Patient.asymp_non_test_based.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all
  end

  test 'isolation requiring review' do
    # setup for test based case
    patient = create(:patient, monitoring: true, purged: false, isolation: true)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count

    # meets definition: has at least 1 assessment and 2 negative test results
    create(:assessment, patient: patient, created_at: 50.days.ago)
    create(:laboratory, patient: patient, result: 'negative', report: 50.days.ago)
    create(:laboratory, patient: patient, result: 'negative', report: 50.days.ago)
    assert_equal 1, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: no assessments
    create(:laboratory, patient: patient, result: 'negative')
    create(:laboratory, patient: patient, result: 'negative')
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Laboratory.destroy_all

    # does not meet definition: only 1 negative test result
    create(:assessment, patient: patient)
    create(:laboratory, patient: patient, result: 'negative')
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # setup for non test based case
    patient = create(:patient, monitoring: true, purged: false, isolation: true, symptom_onset: 12.days.ago)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count

    # meets definition: assessment older than 72 hours
    create(:assessment, patient: patient, created_at: 80.hours.ago)
    assert_equal 1, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all

    # does not meet definition: assessment not older than 72 hours
    create(:assessment, patient: patient, created_at: 70.hours.ago)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all

    # does not meet definition: had a fever within the past 72 hours
    create(:assessment, patient: patient, created_at: 80.hours.ago)
    assessment_2 = create(:assessment, patient: patient, created_at: 70.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment_2)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'fever', bool_value: true)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all

    # does not meet definition: used a fever reducer within the past 72 hours
    create(:assessment, patient: patient, created_at: 80.hours.ago)
    assessment_2 = create(:assessment, patient: patient, created_at: 70.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment_2)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'used-a-fever-reducer', bool_value: true)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all

    # meets definition: had an assessment with no fever
    create(:assessment, patient: patient, created_at: 80.hours.ago)
    assessment_2 = create(:assessment, patient: patient, created_at: 70.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment_2)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'fever', bool_value: false)
    assert_equal 1, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all

    # meets definition: had a fever more than 72 hours ago
    assessment = create(:assessment, patient: patient, created_at: 80.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'fever', bool_value: true)
    assert_equal 1, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all

    # setup for asymp non test based case
    patient = create(:patient, monitoring: true, purged: false, isolation: true)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count

    # meets definition: asymptomatic after positive test result
    create(:laboratory, patient: patient, result: 'positive', report: 15.days.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 8.days.ago)
    assert_equal 1, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # meets definition: only symptomatic before positive test result but not afterwards
    create(:assessment, patient: patient, symptomatic: true, created_at: 12.days.ago)
    create(:laboratory, patient: patient, result: 'positive', report: 11.days.ago)
    assert_equal 1, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet defiition: has positive test result less than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', report: 8.days.ago)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Laboratory.destroy_all

    # does not meet defiition: has positive test result more than 10 days ago, but also has positive test result less than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', report: 11.days.ago)
    create(:laboratory, patient: patient, result: 'positive', report: 9.days.ago)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Laboratory.destroy_all

    # does not meet defiition: has negative test result more than 10 days ago, but also has positive test result less than 10 days ago
    create(:laboratory, patient: patient, result: 'negative', report: 11.days.ago)
    create(:laboratory, patient: patient, result: 'positive', report: 9.days.ago)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Laboratory.destroy_all

    # does not meet defiition: has positive test result more than 10 days ago, but also has positive test result less than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', report: 11.days.ago)
    create(:laboratory, patient: patient, result: 'negative', report: 9.days.ago)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result
    create(:laboratory, patient: patient, result: 'positive', report: 15.days.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 8.days.ago)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', report: 13.days.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 12.days.ago)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', report: 12.days.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 6.days.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 5.days.ago)
    create(:laboratory, patient: patient, result: 'negative', report: 3.days.ago)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', report: 15.days.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 14.days.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 13.days.ago)
    create(:laboratory, patient: patient, result: 'negative', report: 12.days.ago)
    assert_equal 0, Patient.isolation_requiring_review.where(id: patient.id).count
    Assessment.destroy_all
    Laboratory.destroy_all
  end

  test 'isolation non reporting' do
    # setup
    patient = create(:patient, monitoring: true, purged: false, isolation: true)
    assert_equal 0, Patient.isolation_non_reporting.where(id: patient.id).count

    # meets definition: patient was created more than 24 hours ago with no assessments
    patient = create(:patient, monitoring: true, purged: false, isolation: true, created_at: 2.days.ago)
    assert_equal 1, Patient.isolation_non_reporting.where(id: patient.id).count

    # does not meet definition: patient has asymptomatic assessment less than 24 hours ago
    create(:assessment, patient: patient, symptomatic: false, created_at: 10.hours.ago)
    assert_equal 0, Patient.isolation_non_reporting.where(id: patient.id).count
    Assessment.destroy_all

    # does not meet definition: patient has symptomatic assessment less than 24 hours ago
    create(:assessment, patient: patient, symptomatic: true, created_at: 18.hours.ago)
    assert_equal 0, Patient.isolation_non_reporting.where(id: patient.id).count
    Assessment.destroy_all

    # meets definition: patient has asymptomatic assessment more than 24 hours ago
    create(:assessment, patient: patient, symptomatic: false, created_at: 25.hours.ago)
    assert_equal 1, Patient.isolation_non_reporting.where(id: patient.id).count
    Assessment.destroy_all

    # meets definition: patient has symptomatic assessment more than 24 hours ago
    create(:assessment, patient: patient, symptomatic: true, created_at: 28.hours.ago)
    assert_equal 1, Patient.isolation_non_reporting.where(id: patient.id).count
    Assessment.destroy_all
  end

  test 'isolation reporting' do
    # setup
    patient = create(:patient, monitoring: true, purged: false, isolation: true)
    assert_equal 1, Patient.isolation_reporting.where(id: patient.id).count

    # does not meet definition: patient was created more than 24 hours ago
    patient = create(:patient, monitoring: true, purged: false, isolation: true, created_at: 2.days.ago)
    assert_equal 0, Patient.isolation_reporting.where(id: patient.id).count

    # meets definition: patient has asymptomatic assessment less than 24 hours ago
    create(:assessment, patient: patient, symptomatic: false, created_at: 10.hours.ago)
    assert_equal 1, Patient.isolation_reporting.where(id: patient.id).count
    Assessment.destroy_all

    # meets definition: patient has symptomatic assessment less than 24 hours ago
    create(:assessment, patient: patient, symptomatic: true, created_at: 18.hours.ago)
    assert_equal 1, Patient.isolation_reporting.where(id: patient.id).count
    Assessment.destroy_all

    # does not meet definition: patient has asymptomatic assessment more than 24 hours ago
    create(:assessment, patient: patient, symptomatic: false, created_at: 25.hours.ago)
    assert_equal 0, Patient.isolation_reporting.where(id: patient.id).count
    Assessment.destroy_all

    # does not meet definition: patient has symptomatic assessment more than 24 hours ago
    create(:assessment, patient: patient, symptomatic: true, created_at: 28.hours.ago)
    assert_equal 0, Patient.isolation_reporting.where(id: patient.id).count
    Assessment.destroy_all
  end

  test 'address timezone offset' do
    jur = Jurisdiction.create
    user = User.create!(
      email: 'foobar@example.com',
      password: '1234567ab!',
      jurisdiction: jur,
      force_password_change: true # Require user to change password on first login
    )
    Patient.destroy_all
    patient = Patient.new(creator: user, jurisdiction: jur)
    patient.responder = patient
    patient.save
    assert patient.address_timezone_offset == '-04:00'
    patient.update(address_state: 'California')
    assert patient.address_timezone_offset == '-07:00'
    patient.update(monitored_address_state: 'Northern Mariana Islands')
    assert patient.address_timezone_offset == '+10:00'
  end
end
