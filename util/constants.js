const path = require('path');
const capitalize = require('./capitalize');
const { version, name } = require('../package.json');

const SOURCE = path.join(__dirname, '..', name);
const DESTINATION = path.join(__dirname, '..', `${name}_v${version}.zip`);
const PROJECT = capitalize(name);

module.exports = { SOURCE, DESTINATION, PROJECT };
