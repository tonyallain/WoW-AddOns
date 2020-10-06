const config = require('config');
const request = require('supertest');

const { host, apiKey } = config.get('curseforge');

// https://www.curseforge.com/wow/addons/conditioner/files/3071222

const auth = () =>
  request(host)
    .get('/game/versions')
    .query({ token: apiKey })
    .then(res => console.log(res.body));

auth();
