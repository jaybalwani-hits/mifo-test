'use strict';
const Knex = require('knex');
const {Connector} = require('@google-cloud/cloud-sql-connector');

const getIpType = () =>
  process.env.PRIVATE_IP === '1' || process.env.PRIVATE_IP === 'true'
    ? 'PRIVATE'
    : 'PUBLIC';

const connectWithConnector = async (config = {}) => {
  const connector = new Connector();
  const clientOpts = await connector.getOptions({
    instanceConnectionName: process.env.INSTANCE_CONNECTION_NAME,
    ipType: getIpType(),
  });
  const dbConfig = {
    client: 'pg',
    connection: {
      ...clientOpts,
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME,
    },
    ...config,
  };
  return Knex(dbConfig);
};

module.exports = connectWithConnector;
