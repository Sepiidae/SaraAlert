# frozen_string_literal: true

require 'test_helper'

class ApiControllerTest < ActionDispatch::IntegrationTest
  fixtures :all

  setup do
    @user = User.find_by(email: 'state1_epi@example.com')
    read_write_app = Doorkeeper::Application.create(name: 'test-rw',
                                                    redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                    scopes: 'user/*.*')
    read_app = Doorkeeper::Application.create(name: 'test-r',
                                              redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                              scopes: 'user/*.read')
    write_app = Doorkeeper::Application.create(name: 'test-w',
                                               redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                               scopes: 'user/*.write')
    @token_rw = Doorkeeper::AccessToken.create(resource_owner_id: @user.id, application: read_write_app, scopes: 'user/*.read user/*.write')
    @token_r = Doorkeeper::AccessToken.create(resource_owner_id: @user.id, application: read_app, scopes: 'user/*.read')
    @token_w = Doorkeeper::AccessToken.create(resource_owner_id: @user.id, application: write_app, scopes: 'user/*.write')
    @patient_1 = Patient.find_by(id: 1).as_fhir
    Patient.find_by(id: 2).update(preferred_contact_method: 'SMS Texted Weblink',
                                  preferred_contact_time: 'Afternoon',
                                  last_date_of_exposure: 4.days.ago,
                                  symptom_onset: 3.days.ago,
                                  isolation: true)
    @patient_2 = Patient.find_by(id: 2).as_fhir
  end

  test 'should be 406 when bad accept header via show' do
    get '/fhir/r4/Patient/1', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'foo/bar' }
    assert_response :not_acceptable
  end

  test 'should be unauthorized via show' do
    get '/fhir/r4/Patient/1'
    assert_response :unauthorized
  end

  test 'should be unauthorized via show write only' do
    get '/fhir/r4/Patient/1', headers: { 'Authorization': "Bearer #{@token_w.token}", 'Accept': 'application/fhir+json' }
    assert_response :forbidden
  end

  test 'should get patient via show' do
    get '/fhir/r4/Patient/1', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 3, json_response['telecom'].count
    assert_equal 'Boehm62', json_response['name'].first['family']
    assert_equal 'Telephone call', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-method' }.first['valueString']
    assert_equal 'Morning', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-time' }.first['valueString']
    assert_equal 45.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'last-exposure-date' }.first['valueDate']
    assert_equal 5.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'symptom-onset-date' }.first['valueDate']
    assert_not json_response['extension'].filter { |e| e['url'].include? 'isolation' }.first['valueBoolean']
  end

  test 'should get observation via show' do
    get '/fhir/r4/Observation/1001', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1001, json_response['id']
    assert_equal 'Observation', json_response['resourceType']
    assert_equal 'Patient/1', json_response['subject']['reference']
    assert_equal 'positive', json_response['valueString']
  end

  test 'should get QuestionnaireResponse via show' do
    get '/fhir/r4/QuestionnaireResponse/1001', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1001, json_response['id']
    assert_equal 'QuestionnaireResponse', json_response['resourceType']
    assert_equal 'Patient/1', json_response['subject']['reference']
    assert_not json_response['item'].find(text: 'fever').first['answer'].first['valueBoolean']
    assert_not json_response['item'].find(text: 'cough').first['answer'].first['valueBoolean']
    assert_not json_response['item'].find(text: 'difficulty-breathing').first['answer'].first['valueBoolean']
  end

  test 'should be bad request via show' do
    get '/fhir/r4/FooBar/1', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :bad_request
  end

  test 'should be forbidden via show' do
    get '/fhir/r4/Patient/9', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :forbidden
  end

  test 'should be unauthorized via create' do
    post '/fhir/r4/Patient'
    assert_response :unauthorized
  end

  test 'should be unauthorized via create read only' do
    post '/fhir/r4/Patient', params: @patient_1.to_json, headers: { 'Authorization': "Bearer #{@token_r.token}" }
    assert_response :forbidden
  end

  test 'should create Patient via create' do
    post '/fhir/r4/Patient', params: @patient_1.to_json, headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Content-Type': 'application/fhir+json' }
    assert_response :created
    json_response = JSON.parse(response.body)
    id = json_response['id']
    p = Patient.find_by(id: id)
    assert_not p.nil?
    h = History.where(patient_id: id)
    assert_not h.first.nil?
    assert_equal 1, h.count
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 3, json_response['telecom'].count
    assert_equal 'Boehm62', json_response['name'].first['family']
    assert response.headers['Location'].ends_with?(json_response['id'].to_s)
  end

  test 'should be 415 when bad content type header via create' do
    post '/fhir/r4/Patient', params: @patient_1.to_json, headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Content-Type': 'foo/bar' }
    assert_response :unsupported_media_type
  end

  test 'should be bad request via create' do
    post '/fhir/r4/Patient', params: { foo: 'bar' }.to_json, headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Content-Type': 'application/fhir+json' }
    assert_response :bad_request
  end

  test 'should be unauthorized via update' do
    get '/fhir/r4/Patient/1'
    assert_response :unauthorized
  end

  test 'should be unauthorized via update read only' do
    put '/fhir/r4/Patient/1', params: @patient_1.to_json, headers: { 'Authorization': "Bearer #{@token_r.token}" }
    assert_response :forbidden
  end

  test 'should update Patient via update' do
    put '/fhir/r4/Patient/1', params: @patient_2.to_json, headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Content-Type': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    p = Patient.find_by(id: 1)
    assert_not p.nil?
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 'Kirlin44', json_response['name'].first['family']
    assert_equal 'SMS Texted Weblink', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-method' }.first['valueString']
    assert_equal 'Afternoon', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-time' }.first['valueString']
    assert_equal 4.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'last-exposure-date' }.first['valueDate']
    assert_equal 3.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'symptom-onset-date' }.first['valueDate']
    assert json_response['extension'].filter { |e| e['url'].include? 'isolation' }.first['valueBoolean']
  end

  test 'should be bad request via update due to bad fhir' do
    put '/fhir/r4/Patient/1', params: { foo: 'bar' }.to_json, headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Content-Type': 'application/fhir+json' }
    assert_response :bad_request
  end

  test 'should be bad request via update due to bad resource' do
    put '/fhir/r4/FooBar/9', params: @patient_2.to_json, headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Content-Type': 'application/fhir+json' }
    assert_response :bad_request
  end

  test 'should be forbidden via update' do
    put '/fhir/r4/Patient/9', params: @patient_2.to_json, headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Content-Type': 'application/fhir+json' }
    assert_response :forbidden
  end

  test 'should be unauthorized via search' do
    get '/fhir/r4/Patient?family=Kirlin44'
    assert_response :unauthorized
  end

  test 'should be unauthorized via search write only' do
    get '/fhir/r4/Patient?family=Kirlin44', headers: { 'Authorization': "Bearer #{@token_w.token}", 'Accept': 'application/fhir+json' }
    assert_response :forbidden
  end

  test 'should find Observations for a Patient via search' do
    get '/fhir/r4/Observation?subject=Patient/1', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'Observation', json_response['entry'].first['resource']['resourceType']
  end

  test 'should find QuestionnaireResponses for a Patient via search' do
    get '/fhir/r4/QuestionnaireResponse?subject=Patient/1', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'QuestionnaireResponse', json_response['entry'].first['resource']['resourceType']
  end

  test 'should find no Observations for an invalid Patient via search' do
    get '/fhir/r4/Observation?subject=Patient/blah', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'should find no QuestionnaireResponses for an invalid Patient via search' do
    get '/fhir/r4/QuestionnaireResponse?subject=Patient/blah', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'should find Patient via search by _id' do
    get '/fhir/r4/Patient?_id=1', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 1, json_response['entry'].first['resource']['id']
  end

  test 'should find Patient via search on existing family' do
    get '/fhir/r4/Patient?family=Kirlin44', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'should find no Patients via search on non-existing family' do
    get '/fhir/r4/Patient?family=foo', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'should find Patient via search on given' do
    get '/fhir/r4/Patient?given=Chris32', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'should find Patient via search on telecom' do
    get '/fhir/r4/Patient?telecom=%28555%29%20555-0141', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'should find Patient via search on email' do
    get '/fhir/r4/Patient?email=grazyna%40example.com', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'should get Bundle via search without params' do
    get '/fhir/r4/Patient', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    json_response['entry'].each do |entry|
      assert(entry['fullUrl'].include?('Patient') ||
              entry['fullUrl'].include?('Observation') ||
              entry['fullUrl'].include?('QuestionnaireResponse'))
    end
  end

  test 'should be bad request via search' do
    get '/fhir/r4/FooBar?email=grazyna%40example.com', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :bad_request
  end

  test 'should be unauthorized via all' do
    get '/fhir/r4/Patient/1/$everything'
    assert_response :unauthorized
  end

  test 'should be unauthorized via all write only' do
    get '/fhir/r4/Patient/1/$everything', headers: { 'Authorization': "Bearer #{@token_w.token}", 'Accept': 'application/fhir+json' }
    assert_response :forbidden
  end

  test 'should get Bundle via all' do
    get '/fhir/r4/Patient/1/$everything', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 5, json_response['total']
    assert_equal 1, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'Patient' }.count
    assert_equal 2, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'QuestionnaireResponse' }.count
    assert_equal 2, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'Observation' }.count
    assert_equal 'Patient/1', json_response['entry'].filter { |e| e['resource']['resourceType'] == 'Observation' }.first['resource']['subject']['reference']
    assert_equal 1, json_response['entry'].first['resource']['id']
  end

  test 'should get patients with default count via search' do
    get '/fhir/r4/Patient', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'http://www.example.com/fhir/r4/Patient?page=2', json_response['link'][0]['url']
  end

  test 'should get patients with count as 100 via search' do
    get '/fhir/r4/Patient?_count=100', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_nil json_response['link']
  end

  test 'should only get summary with count as 0 via search' do
    get '/fhir/r4/Patient?_count=0', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_nil json_response['link']
  end

  test 'should be forbidden via all' do
    get '/fhir/r4/Patient/9/$everything', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :forbidden
  end

  test 'should get CapabilityStatement unauthorized via capability_statement' do
    get '/fhir/r4/metadata', headers: { 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal ADMIN_OPTIONS['version'], json_response['software']['version']
  end

  test 'should get CapabilityStatement authorized via capability_statement' do
    get '/fhir/r4/metadata', headers: { 'Authorization': "Bearer #{@token_rw.token}", 'Accept': 'application/fhir+json' }
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal ADMIN_OPTIONS['version'], json_response['software']['version']
  end
end
