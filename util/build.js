const archiver = require('archiver');
const fs = require('fs');
const { SOURCE, DESTINATION, PROJECT } = require('./constants');

const build = () => {
  const output = fs.createWriteStream(DESTINATION);
  const archive = archiver('zip');

  output.on('close', () => {
    console.log(archive.pointer() + ' total bytes');
  });

  output.on('end', () => {
    console.log('data drained');
  });

  archive.pipe(output);

  archive.directory(SOURCE, PROJECT);

  return archive.finalize();
};

module.exports = build;
