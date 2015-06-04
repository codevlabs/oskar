var StringHelper;

StringHelper = (function() {
  function StringHelper() {}

  StringHelper.convertStatusToText = function(status) {
    switch (status) {
      case '1':
        return 'really shit';
      case '2':
        return 'a bit down';
      case '3':
        return 'somewhere in between';
      case '4':
        return 'alright';
      default:
        return 'awesome';
    }
  };

  return StringHelper;

})();

module.exports = StringHelper;
