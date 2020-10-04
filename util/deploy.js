const config = require('config');
const request = require('supertest');

const { host, apiKey } = config.get('curseforge');

const auth = () =>
  request(host)
    .get('/api/game/versions')
    .query({ token: apiKey })
    .then(res => console.log(res.body));

auth();
