import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Form, Modal } from 'react-bootstrap';
import axios from 'axios';

import reportError from '../../util/ReportError';

class CloseRecords extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      apply_to_group: false,
      loading: false,
      monitoring_reasons: [
        'Completed Monitoring',
        'Meets Case Definition',
        'Lost to follow-up during monitoring period',
        'Lost to follow-up (contact never established)',
        'Transferred to another jurisdiction',
        'Person Under Investigation (PUI)',
        'Case confirmed',
        'Meets criteria to discontinue isolation',
        'Deceased',
        'Duplicate',
        'Other',
      ],
      monitoring_reason: '',
      reasoning: '',
    };
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
  }

  handleChange(event) {
    if (event.target.id === 'monitoring_reason') {
      this.setState({ monitoring_reason: event.target.value });
    } else if (event.target.id === 'reasoning') {
      this.setState({ reasoning: event.target.value });
    } else if (event.target.id === 'apply_to_group') {
      this.setState({ apply_to_group: event.target.checked });
    }
  }

  submit() {
    let idArray = this.props.patients.map(x => x['id']);

    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/bulk_edit/status', {
          ids: idArray,
          comment: true,
          message: 'monitoring status to "Not Monitoring".',
          monitoring: false,
          monitoring_reason: this.state.monitoring_reason,
          reasoning: this.state.monitoring_reason + (this.state.monitoring_reason !== '' && this.state.reasoning !== '' ? ', ' : '') + this.state.reasoning,
          apply_to_group: this.state.apply_to_group,
        })
        .then(() => {
          location.href = window.BASE_PATH;
        })
        .catch(error => {
          reportError(error);
          this.setState({ loading: false });
        });
    });
  }

  render() {
    return (
      <React.Fragment>
        <Modal.Body>
          <p>
            <span>
              You are about to change the Monitoring Status of the selected records from &quot;Actively Monitoring&quot; to &quot;Not Monitoring&quot;.
            </span>
            {this.state.monitoring_reason === '' && <span> These records will be moved to the closed line list and the reason for closure will be blank.</span>}
          </p>
          <Form.Group>
            <Form.Label>Please select reason for status change:</Form.Label>
            <Form.Control as="select" size="lg" className="form-square" id="monitoring_reason" onChange={this.handleChange} defaultValue={-1}>
              <option value={''}>--</option>
              {this.state.monitoring_reasons.map((option, index) => (
                <option key={`option-${index}`} value={option}>
                  {option}
                </option>
              ))}
            </Form.Control>
          </Form.Group>
          <Form.Group>
            <Form.Label>Please include any additional details:</Form.Label>
            <Form.Control as="textarea" rows="2" id="reasoning" onChange={this.handleChange} />
          </Form.Group>
          <Form.Group className="my-2">
            <Form.Check
              type="switch"
              id="apply_to_group"
              label="Apply this change to the entire household that these monitorees are responsible for, if it applies."
              checked={this.state.apply_to_group === true || false}
              onChange={this.handleChange}
            />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.props.close}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={this.submit}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Submit
          </Button>
        </Modal.Footer>
      </React.Fragment>
    );
  }
}

CloseRecords.propTypes = {
  authenticity_token: PropTypes.string,
  patients: PropTypes.array,
  close: PropTypes.func,
};

export default CloseRecords;
