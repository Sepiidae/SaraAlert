import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Row } from 'react-bootstrap';
import Pagination from 'jw-react-pagination';
import Select from 'react-select';
import axios from 'axios';

import History from './History';
import InfoTooltip from '../util/InfoTooltip';
import reportError from '../util/ReportError';

class HistoryComponent extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: false,
      comment: '',
      selectedFilters: [],
      filteredHistories: this.props.histories,
      pageOfHistories: [],
    };

    this.handleTextChange = this.handleTextChange.bind(this);
    this.onChangePage = this.onChangePage.bind(this);
    this.submit = this.submit.bind(this);
  }

  handleTextChange(event) {
    this.setState({ comment: event.target.value });
  }

  onChangePage(pageOfHistories) {
    this.setState({ pageOfHistories });
  }

  submit() {
    this.setState({ loading: true }, () => {
      axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
      axios
        .post(window.BASE_PATH + '/histories', {
          patient_id: this.props.patient_id,
          comment: this.state.comment,
        })
        .then(() => {
          location.reload(true);
        })
        .catch(error => {
          reportError(error);
        });
    });
  }

  filterHistories = () => {
    let filteredHistories = [...this.props.histories];
    if (this.state.selectedFilters.length !== 0) {
      filteredHistories = filteredHistories.filter(history => {
        return this.state.selectedFilters.includes(history.history_type);
      });
    }
    this.setState({
      filteredHistories,
    });
  };

  handleFilterChange = inputValue => {
    let selectedFilters = [];
    if (Array.isArray(inputValue) && inputValue.length) {
      selectedFilters = inputValue.map(x => x.value);
    }
    this.setState(
      {
        selectedFilters,
      },
      () => {
        this.filterHistories();
      }
    );
  };

  render() {
    const historiesArray = this.state.pageOfHistories.map(history => <History key={history.id} history={history} />);

    const filterOptions = [
      {
        label: 'History Type',
        options: [
          { value: 'Comment', label: 'Comment' },
          { value: 'Contact Attempt', label: 'Contact Attempt' },
          { value: 'Enrollment', label: 'Enrollment' },
          { value: 'Lab Result', label: 'Lab Result' },
          { value: 'Lab Result Edit', label: 'Lab Result Edit' },
          { value: 'Monitoree Data Downloaded', label: 'Monitoree Data Downloaded' },
          { value: 'Monitoring Change', label: 'Monitoring Change' },
          { value: 'Report Created', label: 'Report Created' },
          { value: 'Report Note', label: 'Report Note' },
          { value: 'Report Reminder', label: 'Report Reminder' },
          { value: 'Report Reviewed', label: 'Report Reviewed' },
          { value: 'Report Updated', label: 'Report Updated' },
          { value: 'Reports Reviewed', label: 'Reports Reviewed' },
        ],
      },
    ];

    return (
      <React.Fragment>
        <Card className="mx-2 mt-3 mb-4 card-square">
          <Card.Header>
            <div className="d-flex flex-row align-items-center">
              <h5 className="float-left flex-grow-1 mb-0">
                <span>History </span>
                <InfoTooltip tooltipTextKey="history" location="right"></InfoTooltip>
              </h5>
            </div>
          </Card.Header>
          <Card.Body className="py-0 px-1">
            <Row className="mx-3 mt-3 justify-content-end">
              <Select
                closeMenuOnSelect={false}
                isMulti
                name="Filters"
                options={filterOptions}
                className="basic-multi-select w-25"
                classNamePrefix="select"
                placeholder="Filters"
                theme={theme => ({
                  ...theme,
                  borderRadius: 0,
                })}
                onChange={this.handleFilterChange}
              />
            </Row>
            {historiesArray}
            <Row className="mx-3 mt-3 justify-content-end">
              <Pagination pageSize={5} maxPages={5} items={this.state.filteredHistories} onChangePage={this.onChangePage} />
            </Row>
            <Card className="mb-4 mt-4 mx-3 card-square shadow-sm">
              <Card.Header>Add Comment</Card.Header>
              <Card.Body>
                <textarea
                  id="comment"
                  name="comment"
                  className="form-control"
                  style={{ resize: 'none' }}
                  rows="3"
                  placeholder="enter comment here..."
                  value={this.state.comment}
                  onChange={this.handleTextChange}
                />
                <button
                  className="mt-3 btn btn-primary btn-square float-right"
                  disabled={this.state.loading || this.state.comment === ''}
                  onClick={this.submit}>
                  <i className="fas fa-comment-dots"></i> Add Comment
                </button>
              </Card.Body>
            </Card>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

HistoryComponent.propTypes = {
  patient_id: PropTypes.number,
  histories: PropTypes.array,
  authenticity_token: PropTypes.string,
};

export default HistoryComponent;
