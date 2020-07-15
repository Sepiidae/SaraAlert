# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
class EnrollmentFormSteps < ApplicationSystemTestCase
  # rubocop:disable Layout/LineLength
  def steps
    {
      identification: [
        { id: 'first_name', type: 'text', required: true, info_page: true },
        { id: 'middle_name', type: 'text', required: false, info_page: true },
        { id: 'last_name', type: 'text', required: true, info_page: true },
        { id: 'date_of_birth', type: 'date', required: true, info_page: true },
        { id: 'age', type: 'age', required: false, info_page: true },
        { id: 'sex', type: 'select', required: false, info_page: true },
        { id: 'white', type: 'race', required: false, info_page: 'White', label: 'WHITE' },
        { id: 'black_or_african_american', type: 'race', required: false, info_page: 'Black or African American', label: 'BLACK OR AFRICAN AMERICAN' },
        { id: 'american_indian_or_alaska_native', type: 'race', required: false, info_page: 'American Indian or Alaska Native', label: 'AMERICAN INDIAN OR ALASKA NATIVE' },
        { id: 'asian', type: 'race', required: false, info_page: 'Asian', label: 'ASIAN' },
        { id: 'native_hawaiian_or_other_pacific_islander', type: 'race', required: false, info_page: 'Native Hawaiian or Other Pacific Islander', label: 'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER' },
        { id: 'ethnicity', type: 'select', required: false, info_page: true },
        { id: 'primary_language', type: 'select', required: false, info_page: true },
        { id: 'secondary_language', type: 'select', required: false, info_page: false },
        { id: 'interpretation_required', type: 'checkbox', required: false, info_page: false, label: 'INTERPRETATION REQUIRED' },
        { id: 'nationality', type: 'text', required: false, info_page: true },
        { id: 'user_defined_id_statelocal', type: 'text', required: false, info_page: true },
        { id: 'user_defined_id_cdc', type: 'text', required: false, info_page: true },
        { id: 'user_defined_id_cdc', type: 'text', required: false, info_page: true },
        { id: 'user_defined_id_nndss', type: 'text', required: false, info_page: true }
      ],
      address: [
        { id: 'address_line_1', type: 'text', required: true, info_page: true, tab: 'Home Address Within USA', copiable: true },
        { id: 'address_city', type: 'text', required: true, info_page: true, tab: 'Home Address Within USA', copiable: true },
        { id: 'address_state', type: 'select', required: true, info_page: true, tab: 'Home Address Within USA', copiable: true },
        { id: 'address_line_2', type: 'text', required: false, info_page: true, tab: 'Home Address Within USA', copiable: true },
        { id: 'address_zip', type: 'text', required: true, info_page: true, tab: 'Home Address Within USA', copiable: true },
        { id: 'address_county', type: 'text', required: false, info_page: true, tab: 'Home Address Within USA', copiable: true },
        { id: 'monitored_address_line_1', type: 'text', required: false, info_page: false, tab: 'Home Address Within USA' },
        { id: 'monitored_address_city', type: 'text', required: false, info_page: false, tab: 'Home Address Within USA' },
        { id: 'monitored_address_state', type: 'select', required: false, info_page: false, tab: 'Home Address Within USA' },
        { id: 'monitored_address_line_2', type: 'text', required: false, info_page: false, tab: 'Home Address Within USA' },
        { id: 'monitored_address_zip', type: 'text', required: false, info_page: false, tab: 'Home Address Within USA' },
        { id: 'monitored_address_county', type: 'text', required: false, info_page: false, tab: 'Home Address Within USA' },
        { id: 'foreign_address_line_1', type: 'text', required: false, info_page: true, tab: 'Home Address Outside USA (Foreign)' },
        { id: 'foreign_address_city', type: 'text', required: false, info_page: true, tab: 'Home Address Outside USA (Foreign)' },
        { id: 'foreign_address_country', type: 'select', required: false, info_page: true, tab: 'Home Address Outside USA (Foreign)' },
        { id: 'foreign_address_line_2', type: 'text', required: false, info_page: true, tab: 'Home Address Outside USA (Foreign)' },
        { id: 'foreign_address_zip', type: 'text', required: false, info_page: true, tab: 'Home Address Outside USA (Foreign)' },
        { id: 'foreign_address_line_3', type: 'text', required: false, info_page: false, tab: 'Home Address Outside USA (Foreign)' },
        { id: 'foreign_address_state', type: 'text', required: false, info_page: false, tab: 'Home Address Outside USA (Foreign)' },
        { id: 'foreign_monitored_address_line_1', type: 'text', required: false, info_page: false, tab: 'Home Address Outside USA (Foreign)' },
        { id: 'foreign_monitored_address_city', type: 'text', required: false, info_page: false, tab: 'Home Address Outside USA (Foreign)' },
        { id: 'foreign_monitored_address_state', type: 'select', required: false, info_page: false, tab: 'Home Address Outside USA (Foreign)' },
        { id: 'foreign_monitored_address_line_2', type: 'text', required: false, info_page: false, tab: 'Home Address Outside USA (Foreign)' },
        { id: 'foreign_monitored_address_zip', type: 'text', required: false, info_page: false, tab: 'Home Address Outside USA (Foreign)' },
        { id: 'foreign_monitored_address_county', type: 'text', required: false, info_page: false, tab: 'Home Address Outside USA (Foreign)' }
      ],
      contact_info: [
        { id: 'preferred_contact_method', type: 'select', required: true, info_page: false },
        { id: 'preferred_contact_time', type: 'select', required: false, info_page: true },
        { id: 'primary_telephone', type: 'text', required: false, info_page: true },
        { id: 'primary_telephone_type', type: 'select', required: false, info_page: true },
        { id: 'secondary_telephone', type: 'text', required: false, info_page: false },
        { id: 'secondary_telephone_type', type: 'select', required: false, info_page: false },
        { id: 'email', type: 'text', required: false, info_page: true },
        { id: 'confirm_email', type: 'text', required: false, info_page: false }
      ],
      arrival_info: [
        { id: 'port_of_origin', type: 'text', required: false, info_page: true },
        { id: 'date_of_departure', type: 'date', required: false, info_page: true },
        { id: 'source_of_report', type: 'select', required: false, info_page: false },
        { id: 'flight_or_vessel_number', type: 'text', required: false, info_page: true },
        { id: 'flight_or_vessel_carrier', type: 'text', required: false, info_page: true },
        { id: 'port_of_entry_into_usa', type: 'text', required: false, info_page: true },
        { id: 'date_of_arrival', type: 'date', required: false, info_page: true },
        { id: 'travel_related_notes', type: 'text', required: false, info_page: false }
      ],
      additional_planned_travel: [
        { id: 'additional_planned_travel_type', type: 'select', required: false, info_page: true },
        { id: 'additional_planned_travel_destination', type: 'text', required: false, info_page: false },
        { id: 'additional_planned_travel_destination_state', type: 'select', required: false, info_page: true },
        { id: 'additional_planned_travel_destination_country', type: 'select', required: false, info_page: true },
        { id: 'additional_planned_travel_country', type: 'select', required: false, info_page: true },
        { id: 'additional_planned_travel_port_of_departure', type: 'text', required: false, info_page: true },
        { id: 'additional_planned_travel_start_date', type: 'date', required: false, info_page: true },
        { id: 'additional_planned_travel_end_date', type: 'date', required: false, info_page: true },
        { id: 'additional_planned_travel_related_notes', type: 'text', required: false, info_page: false }
      ],
      potential_exposure_info: [
        { id: 'last_date_of_exposure', type: 'date', required: true, info_page: true },
        { id: 'potential_exposure_location', type: 'text', required: false, info_page: true },
        { id: 'potential_exposure_country', type: 'select', required: false, info_page: true },
        { id: 'contact_of_known_case', type: 'risk factor', required: false, info_page: true, label: 'CLOSE CONTACT WITH A KNOWN CASE' },
        { id: 'contact_of_known_case_id', type: 'text', required: false, info_page: true },
        { id: 'travel_to_affected_country_or_area', type: 'risk factor', required: false, info_page: true, label: 'TRAVEL FROM AFFECTED COUNTRY OR AREA' },
        { id: 'was_in_health_care_facility_with_known_cases', type: 'risk factor', required: false, info_page: true, label: 'WAS IN HEALTH CARE FACILITY WITH KNOWN CASES' },
        { id: 'was_in_health_care_facility_with_known_cases_facility_name', type: 'text', required: false, info_page: true },
        { id: 'laboratory_personnel', type: 'risk factor', required: false, info_page: true, label: 'LABORATORY PERSONNEL' },
        { id: 'laboratory_personnel_facility_name', type: 'text', required: false, info_page: true },
        { id: 'healthcare_personnel', type: 'risk factor', required: false, info_page: true, label: 'HEALTHCARE PERSONNEL' },
        { id: 'healthcare_personnel_facility_name', type: 'text', required: false, info_page: true },
        { id: 'crew_on_passenger_or_cargo_flight', type: 'risk factor', required: false, info_page: true, label: 'CREW ON PASSENGER OR CARGO FLIGHT' },
        { id: 'member_of_a_common_exposure_cohort', type: 'risk factor', required: false, info_page: true, label: 'MEMBER OF A COMMON EXPOSURE COHORT' },
        { id: 'member_of_a_common_exposure_cohort_type', type: 'text', required: false, info_page: true },
        { id: 'jurisdiction_id', type: 'text', required: false, info_page: true },
        { id: 'update_group_member_jurisdiction_id', type: 'checkbox', required: false, info_page: false, label: 'Apply this change to the entire household that this monitoree is responsible for' },
        { id: 'assigned_user', type: 'text', required: false, info_page: true },
        { id: 'update_group_member_assigned_user', type: 'checkbox', required: false, info_page: false, label: 'Apply this change to the entire household that this monitoree is responsible for' },
        { id: 'exposure_risk_assessment', type: 'select', required: false, info_page: false },
        { id: 'monitoring_plan', type: 'select', required: false, info_page: false },
        { id: 'exposure_notes', type: 'text', required: false, info_page: false }
      ]
    }
  end
  # rubocop:enable Layout/LineLength
end
# rubocop:enable Metrics/MethodLength
