# frozen_string_literal: true

require 'test_case'

class ReportedConditionTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create reported condition' do
    assert create(:reported_condition)
    assert create(:reported_condition, threshold_condition_hash: Faker::Alphanumeric.alphanumeric(number: 64))

    error = assert_raises(ActiveRecord::RecordInvalid) do
      create(:reported_condition, assessment: nil)
    end
    assert_includes(error.message, 'Assessment')
  end

  test 'threshold condition' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_condition_1 = create(:threshold_condition, threshold_condition_hash: threshold_condition_hash)
    reported_condition = create(:reported_condition, threshold_condition_hash: threshold_condition_hash)

    # Single ThresholdCondition matches
    assert_equal(threshold_condition_1, reported_condition.threshold_condition)

    # More than one ThresholdCondition matches
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash)
    # Uses the default sort order, we expect the threshold_condition with a lower id.
    assert_equal(threshold_condition_1, reported_condition.threshold_condition)

    # No ThresholdCondition matches
    assert_nil(create(:reported_condition,
                      threshold_condition_hash: Faker::Alphanumeric.alphanumeric(number: 64)).threshold_condition)
  end

  test 'fever medication' do
    assert_difference('ReportedCondition.fever_medication.size', 1) do
      fever_medication_symptom = create(:fever_medication_symptom)
      create(:reported_condition, symptoms: [fever_medication_symptom])
    end

    assert_no_difference('ReportedCondition.fever_medication.size') do
      fever_medication_symptom = create(:fever_medication_symptom, bool_value: false)
      create(:reported_condition, symptoms: [fever_medication_symptom])
    end

    assert_no_difference('ReportedCondition.fever_medication.size') do
      fever_symptom = create(:fever_symptom)
      create(:reported_condition, symptoms: [fever_symptom])
    end
  end

  test 'reported condition fever' do
    assert_difference('ReportedCondition.fever.size', 1) do
      fever_symptom = create(:fever_symptom)
      create(:reported_condition, symptoms: [fever_symptom])
    end

    assert_no_difference('ReportedCondition.fever.size') do
      fever_symptom = create(:fever_symptom, bool_value: false)
      create(:reported_condition, symptoms: [fever_symptom])
    end

    assert_no_difference('ReportedCondition.fever.size') do
      fever_medication_symptom = create(:fever_medication_symptom)
      create(:reported_condition, symptoms: [fever_medication_symptom])
    end
  end
end