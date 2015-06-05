var StringHelper;

StringHelper = (function() {
  function StringHelper() {}

  StringHelper.convertStatusToText = function(status) {
    switch (status) {
      case '1':
        return 'pretty bad';
      case '2':
        return 'a bit down';
      case '3':
        return 'alright';
      case '4':
        return 'really good';
      default:
        return 'awesome';
    }
  };

  return StringHelper;

})();

module.exports = StringHelper;
