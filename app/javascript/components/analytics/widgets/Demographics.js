import React from 'react';
import { PropTypes } from 'prop-types';
import { Card, Table } from 'react-bootstrap';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import Switch from 'react-switch';
import _ from 'lodash';

const AGEGROUPS = ['0-19', '20-29', '30-39', '40-49', '50-59', '60-69', '70-79', '>=80'];
const RISKLEVELS = ['High', 'Medium', 'Low', 'No Identified Risk', 'Missing']; // null will be mapped to `missing` later
const SEXES = ['Male', 'Female', 'Unknown'];

class Demographics extends React.Component {
  constructor(props) {
    super(props);
    this.state = { checked: false, viewTotal: this.props.viewTotal };
    this.handleChange = this.handleChange.bind(this);
    this.toggleBetweenActiveAndTotal = this.toggleBetweenActiveAndTotal.bind(this);
    this.obtainValueFromMonitoreeCounts = this.obtainValueFromMonitoreeCounts.bind(this);
    this.ERRORS = !Object.prototype.hasOwnProperty.call(this.props.stats, 'monitoree_counts');
    this.ERRORSTRING = this.ERRORS ? 'Incorrect Object Schema' : null;
    if (!this.ERRORS) {
      this.ageData = this.obtainValueFromMonitoreeCounts(AGEGROUPS, 'Age Group', this.state.viewTotal);
      this.sexData = this.obtainValueFromMonitoreeCounts(SEXES, 'Sex', this.state.viewTotal);
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.viewTotal !== prevProps.viewTotal) {
      this.toggleBetweenActiveAndTotal(this.props.viewTotal);
    }
  }

  obtainValueFromMonitoreeCounts(enumerations, category_type, onlyActive) {
    let activeMonitorees = this.props.stats.monitoree_counts.filter(x => x.active_monitoring === onlyActive);
    let categoryGroups = activeMonitorees.filter(x => x.category_type === category_type);
    return enumerations.map(x => {
      let thisGroup = categoryGroups.filter(group => group.category === x);
      let retVal = { name: x, total: 0 };
      RISKLEVELS.forEach(val => {
        retVal[String(val)] = _.sum(thisGroup.filter(z => z.risk_level === val).map(z => z.total));
        retVal.total += _.sum(thisGroup.filter(z => z.risk_level === val).map(z => z.total));
      });
      return retVal;
    });
  }

  handleChange = checked => this.setState({ checked });

  toggleBetweenActiveAndTotal = viewTotal => {
    this.ageData = this.obtainValueFromMonitoreeCounts(AGEGROUPS, 'Age Group', viewTotal);
    this.sexData = this.obtainValueFromMonitoreeCounts(SEXES, 'Sex', viewTotal);
  };

  renderBarGraph() {
    return (
      <div className="mx-3 mt-2">
        <ResponsiveContainer width="100%" height={400}>
          <BarChart
            width={500}
            height={300}
            data={this.ageData}
            margin={{
              top: 20,
              right: 30,
              left: 20,
              bottom: 5,
            }}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="High" stackId="a" fill="#FA897B" />
            <Bar dataKey="Medium" stackId="a" fill="#FFDD94" />
            <Bar dataKey="Low" stackId="a" fill="#D0E6A5" />
            <Bar dataKey="No Identified Risk" stackId="a" fill="#333" />
            <Bar dataKey="Missing" stackId="a" fill="#BABEC4" />
          </BarChart>
        </ResponsiveContainer>
        <ResponsiveContainer width="100%" height={400}>
          <BarChart
            width={500}
            height={300}
            data={this.sexData}
            margin={{
              top: 20,
              right: 30,
              left: 20,
              bottom: 5,
            }}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="High" stackId="a" fill="#FA897B" />
            <Bar dataKey="Medium" stackId="a" fill="#FFDD94" />
            <Bar dataKey="Low" stackId="a" fill="#D0E6A5" />
            <Bar dataKey="No Identified Risk" stackId="a" fill="#333" />
            <Bar dataKey="Missing" stackId="a" fill="#BABEC4" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    );
  }

  renderTable() {
    return (
      <div>
        <h4 className="text-left">Age (Years)</h4>
        <Table striped hover className="border mt-2">
          <thead>
            <tr>
              <th></th>
              {RISKLEVELS.map(risklevel => (
                <th key={risklevel.toString()}>{risklevel}</th>
              ))}
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            {AGEGROUPS.map(agegroup => (
              <tr key={agegroup.toString() + '1'}>
                <td key={agegroup.toString() + '2'} className="font-weight-bold">
                  {' '}
                  {agegroup}{' '}
                </td>
                {RISKLEVELS.map((risklevel, risklevelIndex) => (
                  <td key={agegroup.toString() + risklevelIndex.toString()}>{this.ageData.find(x => x.name === agegroup)[String(risklevel)]}</td>
                ))}
                <td>{this.ageData.find(x => x.name === agegroup)['total']}</td>
              </tr>
            ))}
          </tbody>
        </Table>
        <h4 className="text-left">Sex</h4>
        <Table striped hover className="border mt-2">
          <thead>
            <tr>
              <th></th>
              {RISKLEVELS.map(risklevel => (
                <th key={risklevel.toString()}>{risklevel}</th>
              ))}
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            {SEXES.map(sexgroup => (
              <tr key={sexgroup.toString() + '1'}>
                <td key={sexgroup.toString() + '2'} className="font-weight-bold">
                  {sexgroup}
                </td>
                {RISKLEVELS.map((risklevel, risklevelIndex) => (
                  <td key={sexgroup.toString() + risklevelIndex.toString()}>{this.sexData.find(x => x.name === sexgroup)[String(risklevel)]}</td>
                ))}
                <td>{this.sexData.find(x => x.name === sexgroup)['total']}</td>
              </tr>
            ))}
          </tbody>
        </Table>
      </div>
    );
  }

  renderErrors() {
    return <div className="text-danger display-6"> ERROR: {this.ERRORSTRING}. </div>;
  }

  renderCard() {
    return (
      <span>
        <div className="text-right">
          <span className="mr-2 display-6"> View Data as Graph </span>
          <Switch onChange={this.handleChange} onColor="#82A0E4" height={18} width={40} uncheckedIcon={false} checked={this.state.checked} />
        </div>
        {this.state.checked ? this.renderBarGraph() : this.renderTable()}
      </span>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Card className="card-square text-center">
          <Card.Header as="h5" className="text-left">
            Among Those {this.state.viewTotal ? 'Ever Monitored (includes current)' : 'Currently Under Active Monitoring'}
          </Card.Header>
          <Card.Body>{this.ERRORS ? this.renderErrors() : this.renderCard()}</Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

Demographics.propTypes = {
  stats: PropTypes.object,
  viewTotal: PropTypes.bool,
};

export default Demographics;
