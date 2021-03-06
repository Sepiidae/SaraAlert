import React from 'react';
import { PropTypes } from 'prop-types';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import axios from 'axios';

import DateInput from '../util/DateInput';
import reportError from '../util/ReportError';

class Laboratory extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showModal: false,
      loading: false,
      lab_type: this.props.lab.lab_type || '',
      specimen_collection: this.props.lab.specimen_collection,
      report: this.props.lab.report,
      result: this.props.lab.result || '',
    };
    this.toggleModal = this.toggleModal.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
  }

  toggleModal() {
    let current = this.state.showModal;
    this.setState({
      showModal: !current,
    });
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value });
  }

  submit() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/laboratories' + (this.props.lab.id ? '/' + this.props.lab.id : ''), {
          patient_id: this.props.patient.id,
          lab_type: this.state.lab_type,
          specimen_collection: this.state.specimen_collection,
          report: this.state.report,
          result: this.state.result,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered onHide={toggle}>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Lab Test Type</Form.Label>
                <Form.Control as="select" className="form-control-lg" id="lab_type" onChange={this.handleChange} value={this.state.lab_type}>
                  <option disabled></option>
                  <option>PCR</option>
                  <option>Antigen</option>
                  <option>Total Antibody</option>
                  <option>IgG Antibody</option>
                  <option>IgM Antibody</option>
                  <option>IgA Antibody</option>
                  <option>Other</option>
                </Form.Control>
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Specimen Collection Date</Form.Label>
                <DateInput
                  id="specimen_collection"
                  date={this.state.specimen_collection}
                  onChange={date => this.setState({ specimen_collection: date })}
                  placement="bottom"
                />
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Report Date</Form.Label>
                <DateInput id="report" date={this.state.report} onChange={date => this.setState({ report: date })} placement="bottom" />
              </Form.Group>
            </Row>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Result</Form.Label>
                <Form.Control as="select" className="form-control-lg" id="result" onChange={this.handleChange} value={this.state.result}>
                  <option disabled></option>
                  <option>positive</option>
                  <option>negative</option>
                  <option>indeterminate</option>
                  <option>other</option>
                </Form.Control>
              </Form.Group>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
          <Button variant="primary btn-square" disabled={this.state.loading} onClick={submit}>
            Create
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        {!this.props.lab.id && (
          <Button onClick={this.toggleModal}>
            <i className="fas fa-plus"></i> Add New Lab Result
          </Button>
        )}
        {this.props.lab.id && (
          <Button variant="link" onClick={this.toggleModal} className="btn btn-link py-0" size="sm">
            <i className="fas fa-edit"></i> Edit
          </Button>
        )}
        {this.state.showModal && this.createModal('Lab Result', this.toggleModal, this.submit)}
      </React.Fragment>
    );
  }
}

Laboratory.propTypes = {
  lab: PropTypes.object,
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default Laboratory;
