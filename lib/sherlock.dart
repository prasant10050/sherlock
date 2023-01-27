library sherlock;

import 'package:sherlock/result.dart';
import 'package:sherlock/types.dart';
import 'package:sherlock/regex.dart';

/// Returns `true`. Can be used to test if "sherlock" is correctly installed.
bool helloSherlock() {
  return true;
}

/// The search functions add the found elements in [results]. No function
/// returns a result.
class Sherlock {
  /// Where to search.
  final List<Element> elements;

  /// Column priorities to sort the results.
  final PriorityMap priorities;

  /// Default column priorities
  static final PriorityMap _defaults = {'*': 1};

  /// The result elements are wrapped into [Result]s.
  List<Result> unsortedResults;

  /// The current manipulated element. Used in loops by the query functions.
  Element _currentElement;

  /// Sorted research findings.
  List<Element> get results {
    /// Gets the results sorted by points.
    var sortedResults = unsortedResults
      ..sort((a, b) => -a.importance.compareTo(b.importance));

    /// Returns a list of [Element], not results.
    /// Results with greatest points are above.
    return sortedResults.map((e) => e.element).toList();
  }

  /// Creates a [Sherlock] instance that will search in [elements] with a given
  /// map of [priorities].
  ///
  /// The parameter [priorities] is optional however the default value for '*'
  /// is 1, and if a map of [priorities] is given, '*' will be set to 1.
  Sherlock({required this.elements, priorities = const {'*': 1}})
      : unsortedResults = [],
        _currentElement = {},
        priorities = {..._defaults, ...priorities};

  /// Resets the [results].
  void forget() {
    unsortedResults = [];
  }

  /// Smart search in [where], from a natural user [input].
  ///
  /// At first, adds perfect matches, to make them on top of the results list.
  /// Then, searches the matches for all keywords of the user [input].
  /// Finally, searches match for any keyword of the user [input].
  ///
  /// The [where] parameter is either equal to `'*'` for global search (in all
  /// columns) or a list of columns.
  void search({dynamic where = "*", required String input}) {
    /// The type of [where] can be either a list of keywords or '*'.
    if ((where.runtimeType != List<String>) && (where.runtimeType != String)) {
      throw TypeError();
    } else if (where.runtimeType == String && where != '*') {
      /// [String] type is only accepted when [where] equals '*'.
      throw Error();
    }

    final inputKeywords = input.split(' ');

    /// Searches for all the keywords at once.
    final regexAll = RegexHelper.all(keywords: inputKeywords);

    /// Searches any word from the keywords.
    final regexAny = RegexHelper.any(keywords: inputKeywords);

    /// Searches globally.
    if (where == '*') {
      queryBool(
        where: where,
        fn: (value) => (value.runtimeType == String)
            ? value.toLowerCase() == input.toLowerCase()
            : false,
      );

      query(where: where, regex: regexAll);
      query(where: where, regex: regexAny);
      return;
    }

    /// Separate the loops

    /// Searches perfect matches.
    for (var column in where) {
      /// The case does not matter.
      queryBool(
        where: column,
        fn: (value) => (value.runtimeType == String)
            ? value.toLowerCase() == input.toLowerCase()
            : false,
      );
    }

    /// Searches in specified columns.
    for (var column in where) {
      /// Searches for all the keywords at once.
      query(where: column, regex: regexAll);
    }

    for (var column in where) {
      /// Searches any word from the keywords.
      query(where: column, regex: regexAny);
    }
  }

  /// Browses the [elements] to perform a search, calls [fn] giving the column
  /// id where the search has to be performed in, and the priority of this
  /// column.
  ///
  /// The definition of [fn] can be whatever, but it is designed to [_addResult]
  /// with the matching values.
  void _queryAny(
    String where,
    void Function(String columnId, int importance) fn,
  ) {
    for (Element element in elements) {
      /// Sets the [_currentElement] in order to be used by the other functions.
      _currentElement = element;

      if (where == '*') {
        /// Performs search in all the columns of the [_currentElement].
        for (var key in _currentElement.keys) {
          fn(
            key,
            priorities[key] ?? priorities['*']!,
          );
        }
      } else {
        /// Performs search in given column [where].
        fn(
          where,
          priorities[where] ?? priorities['*']!,
        );
      }
    }
  }

  /// Searches for values matching with the [regex], in [where].
  ///
  /// The parameter [where] is either '*' (global search) or a column key.
  void query({
    String where = "*",
    required String regex,
    bool caseSensitive = false,
  }) {
    /// Creates the [RegExp] from the given [String] regex.
    var what = RegExp(regex, caseSensitive: caseSensitive);

    /// Adds result when [what] is matching with the [regex].
    ///
    /// Recursive function when [stringOrList] is a [List].
    void add(dynamic stringOrList, int importance) {
      if (stringOrList == null) {
        return;
      }

      if (stringOrList.runtimeType == String) {
        /// The string contains a value matching with the [regex], adds the current
        /// element to the results.
        if (what.hasMatch(stringOrList)) {
          _addResult(importance: importance);
        }

        return;
      }

      /// Recursive call to check each string of the list.
      if (stringOrList.runtimeType == List<String>) {
        /// Calls this function recursively for all the strings of the list.
        for (String string in stringOrList) {
          add(string, importance);
        }

        return;
      }

      /// Recursive call for list of list or list of list of list etc...
      if (stringOrList.runtimeType == List<dynamic>) {
        /// Calls this function recursively for all the objects of the list.
        for (dynamic dyn in stringOrList) {
          add(dyn, importance);
        }

        return;
      }
    }

    /// Performs the query.
    _queryAny(where, (columnId, importance) {
      add(_currentElement[columnId], importance);
    });
  }

  /// Searches for values when a key exists for [what] in [where].
  void queryExist({required String where, required String what}) {
    _queryAny(where, (columnId, importance) {
      /// Searches in the specified column.
      /// When [what] does not exist, does nothing.
      var value = _currentElement[columnId];

      /// Does not exist, or the value exists but it is null.
      if (value == null || value[what] == null) {
        return;
      }

      _addResult(importance: priorities[columnId] ?? priorities['*']!);
    });
  }

  /// Searches for a value corresponding to a boolean expression in [where].
  void queryBool({
    String where = "*",
    required bool Function(dynamic value) fn,
  }) {
    _queryAny(where, (columnId, importance) {
      /// The return value of [fn] is true, it's a match !
      if (fn(_currentElement[columnId])) {
        _addResult(
          importance: priorities[columnId] ?? priorities['*']!,
        );
      }
    });
  }

  /// Searches for a value which is equal to [match], in [where].
  ///
  /// The optional parameter [caseSensitive] can be used only when [match] is a
  /// [String] and the matching value is also a string.
  void queryMatch({
    String where = "*",
    required dynamic match,
    bool? caseSensitive,
  }) {
    bool stringComparison = false;

    /// Parameter [caseSensitive] is set. The comparison must be between two
    /// strings.
    if (caseSensitive != null) {
      if (match.runtimeType != String) {
        throw TypeError();
      }

      stringComparison = true;
    }

    /// It is case sensitive, both [value] and [match] must be lowercased in
    /// order to compare no matter the case.
    if (stringComparison && caseSensitive!) {
      queryBool(
        where: where,
        fn: (value) {
          /// Cannot lowercase a non-string value.
          if (value.runtimeType != String) {
            throw TypeError();
          }

          return value.toLowerCase() == match.toLowerCase();
        },
      );
      return;
    }

    /// Dynamic comparison.
    queryBool(where: where, fn: (value) => value == match);
  }

  /// Adds the [_currentElement] wrapped in a [Result] object, into the
  /// [results].
  void _addResult({required int importance}) {
    /// Avoid duplicates
    for (Result e in unsortedResults) {
      if (e.element == _currentElement) {
        return;
      }
    }

    /// Adds the [_currentElement] to the results, with its [importance].
    unsortedResults.add(
      Result(
        element: _currentElement,
        importance: importance,
      ),
    );
  }
}
