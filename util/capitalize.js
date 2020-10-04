/**
 * Capitalize the first letter of a word
 * @param {string} str
 */
const capitalize = str => {
  if (!str) {
    return '';
  }

  return str[0].toUpperCase() + str.slice(1);
};

module.exports = capitalize;
