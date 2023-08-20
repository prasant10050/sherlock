import 'package:flutter/material.dart';
import 'package:sherlock/completion.dart';
import 'package:sherlock/sherlock.dart';

class SherlockSearchBar extends StatefulWidget {
  final String? hintText;
  final bool? isFullScreen;
  final Color? dividerColor;

  final double? elevation;
  final Color? backgroundColor;
  final Color? overlayColor;
  final BorderSide? side;
  final OutlinedBorder? shape;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  final Sherlock sherlock;
  final SherlockCompletion sherlockCompletion;
  final int? sherlockCompletionMinResults;
  final int? sherlockCompletionMaxResults;
  final void Function(String input, Sherlock sherlock)? onSearch;
  final Iterable<Widget>? barTrailing;
  final Widget? barLeading;
  final GestureTapCallback? onTap;
  final BoxConstraints? constraints;
  final BoxConstraints? viewConstraints;
  final Color? viewBackgroundColor;
  final double? viewElevation;
  final TextStyle? viewHeaderTextStyle;
  final TextStyle? viewHeaderHintStyle;
  final String? viewHintText;
  final Widget? viewLeading;
  final Iterable<Widget>? viewTrailing;
  final BorderSide? viewSide;
  final OutlinedBorder? viewShape;

  final SherlockCompletionsBuilder Function(
      BuildContext context,
      List<String> completions,
      )? completionsBuilder;

  const SherlockSearchBar({
    super.key,
    this.hintText,
    this.isFullScreen,
    this.dividerColor,
    this.elevation,
    this.backgroundColor,
    this.overlayColor,
    this.side,
    this.shape,
    this.padding,
    this.textStyle,
    this.hintStyle,
    required this.sherlock,
    required this.sherlockCompletion,
    this.sherlockCompletionMinResults,
    this.sherlockCompletionMaxResults,
    this.onSearch,
    this.completionsBuilder,
    this.barTrailing,
    this.barLeading,
    this.onTap,
    this.constraints,
    this.viewBackgroundColor,
    this.viewConstraints,
    this.viewElevation,
    this.viewHeaderHintStyle,
    this.viewHeaderTextStyle,
    this.viewHintText,
    this.viewLeading, this.viewTrailing, this.viewShape, this.viewSide,
  });

  @override
  State<StatefulWidget> createState() => _SherlockSearchBarState();
}

class _SherlockSearchBarState extends State<SherlockSearchBar> {
  final SearchController _controller = SearchController();
  List<Widget> _completionWidgets = [];

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      if (widget.onSearch != null) {
        widget.onSearch!(_controller.text, widget.sherlock);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SearchAnchor.bar(
      dividerColor: widget.dividerColor,
      barHintText: widget.hintText,
      isFullScreen: widget.isFullScreen,
      barElevation: MaterialStatePropertyAll(widget.elevation),
      barBackgroundColor: MaterialStatePropertyAll(widget.backgroundColor),
      barOverlayColor: MaterialStatePropertyAll(widget.overlayColor),
      barSide: MaterialStatePropertyAll(widget.side),
      barShape: MaterialStatePropertyAll(widget.shape),
      barPadding: MaterialStatePropertyAll(widget.padding),
      barTextStyle: MaterialStatePropertyAll(widget.textStyle),
      barHintStyle: MaterialStatePropertyAll(widget.hintStyle),
      searchController: _controller,
      barLeading: widget.barLeading,
      constraints: widget.constraints,
      barTrailing: widget.barTrailing,
      viewBackgroundColor: widget.viewBackgroundColor,
      viewConstraints: widget.viewConstraints,
      viewElevation: widget.viewElevation,
      onTap: widget.onTap,
      viewHeaderHintStyle: widget.viewHeaderHintStyle,
      viewHeaderTextStyle: widget.viewHeaderTextStyle,
      viewHintText: widget.viewHintText,
      viewLeading: widget.viewLeading,
      viewShape: widget.viewShape,
      viewSide: widget.viewSide,
      viewTrailing: widget.viewTrailing,
      suggestionsBuilder: (context, controller) {
        // Text inside the input field of the search bar.
        final input = controller.text;
        // SherlockCompletion's results for the input.
        final futureCompletions = widget.sherlockCompletion.input(
          input: input,
          minResults: widget.sherlockCompletionMinResults,
          maxResults: widget.sherlockCompletionMaxResults,
        );

        futureCompletions.then((completions) {
          var stringCompletions = widget.sherlockCompletion.getStrings(fromResults: completions);
          stringCompletions.then((completions) {
            // Builds the completion widgets after the completion results are completed.
            final SherlockCompletionsBuilder builder = (widget.completionsBuilder != null)
                ? widget.completionsBuilder!(context, completions)
                : SherlockCompletionsBuilder(
              completions: completions,
              buildCompletion: (suggestion) =>
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(suggestion),
                  ),
            );

            _completionWidgets = builder.build();
          });
        });

        return _completionWidgets;
      },
    );
  }
}

/// Creates a list of widget in order to be displayed below the search input to
/// show user completions on their search.
class SherlockCompletionsBuilder {
  final List<String> completions;
  final Widget Function(String completion) buildCompletion;

  /// [completions] is the list of strings given by [SherlockCompletion.input]
  /// or in the [SherlockSearchBar.suggestionsBuilder] field:
  /// ```
  /// SherlockSearchBar(
  ///   suggestionsBuilder: (context, suggestions) => SherlockSuggestionsBuilder(
  ///     suggestions: suggestions,
  ///     ...
  ///   ),
  ///   ...
  /// )
  /// ```
  ///
  /// [buildCompletion] builds a widget for the current completion
  /// ```
  /// SherlockCompletionsBuilder(
  ///   completions: completions,
  ///   buildCompletion: (completion) => Text(buildCompletion),
  /// ),
  /// ```
  SherlockCompletionsBuilder({
    required this.completions,
    required this.buildCompletion,
  });

  /// Builds all the completions into widgets.
  List<Widget> build() {
    return completions.map((completion) => buildCompletion(completion)).toList();
  }
}
