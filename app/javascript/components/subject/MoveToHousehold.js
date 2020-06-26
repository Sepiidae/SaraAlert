import React from 'react';
import { Form, Row, Col, Button, Modal } from 'react-bootstrap';
import { PropTypes } from 'prop-types';
import axios from 'axios';
import reportError from '../util/ReportError';

class MoveToHousehold extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      updateDisabled: true,
      showModal: false,
      loading: false,
      groupMembers: [],
    };
    this.toggleModal = this.toggleModal.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.submit = this.submit.bind(this);
    this.getResponders = this.getResponders.bind(this);
  }

  toggleModal() {
    let current = this.state.showModal;
    this.setState({
      updateDisabled: true,
      showModal: !current,
      loading: !current,
    });
    if (!current) {
      this.getResponders();
    }
  }

  handleChange(event) {
    this.setState({ [event.target.id]: event.target.value, updateDisabled: false });
  }

  getResponders() {
    axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
    axios({
      method: 'get',
      url: window.BASE_PATH + '/public_health/patients/self_reporting',
      params: {},
    })
      .then(response => {
        this.setState({
          loading: false,
          groupMembers: JSON.parse(response['data']['self_reporting']),
        });
      })
      .catch(err => {
        reportError(err);
      });
  }

  submit() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/patients/' + this.props.patient.id + '/update_hoh', {
          new_hoh_id: this.state.hoh_selection.split('SaraID: ')[1].split(' ')[0],
        })
        .then(() => {
          this.setState({ updateDisabled: false });
          location.reload(true);
        })
        .catch(error => {
          console.error(error);
        });
    });
  }

  createModal(title, toggle, submit) {
    return (
      <Modal size="lg" show centered>
        <Modal.Header>
          <Modal.Title>{title}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Row>
              <Form.Group as={Col}>
                <Form.Label className="nav-input-label">Select The New Monitoree That Will Respond For The Current Monitoree</Form.Label>
                <Form.Label size="sm" className="nav-input-label">
                  Note: The current monitoree will be moved into the selected monitorees household
                </Form.Label>
                <Form.Control
                  className="form-square"
                  id="hoh_selection"
                  onChange={this.handleChange}
                  as="input"
                  name="newhohcandidate"
                  list="newhohcandidates"
                  autoComplete="on"
                  size="lg"
                />
                <datalist id="newhohcandidates">
                  {this.state?.groupMembers
                    ?.sort((a, b) => (a.last_name > b.last_name ? 1 : -1))
                    .map((member, index) => {
                      return (
                        <option key={`option-${index}`} data-value={member.id}>
                          {member.last_name}, {member.first_name} Age: {member.age} SaraID: {member.id} StateID: {member.state_id}
                        </option>
                      );
                    })}
                </datalist>
              </Form.Group>
            </Row>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="primary btn-square" onClick={submit} disabled={this.state.updateDisabled || this.state.loading}>
            {this.state.loading && (
              <React.Fragment>
                <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>&nbsp;
              </React.Fragment>
            )}
            Update
          </Button>
          <Button variant="secondary btn-square" onClick={toggle}>
            Cancel
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Button size="sm" className="my-2" onClick={this.toggleModal}>
          <i className="fas fa-house-user"></i> Move To Household
        </Button>
        {this.state.showModal && this.createModal('Move To Household', this.toggleModal, this.submit)}
      </React.Fragment>
    );
  }
}

MoveToHousehold.propTypes = {
  patient: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default MoveToHousehold;