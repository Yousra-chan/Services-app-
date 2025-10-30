import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'search_constants.dart';

// 💡 This is the SearchDelegate implementation.
// It will manage the search bar, suggestions, and results presentation.
class CustomServiceSearchDelegate extends SearchDelegate<String> {
  // Use a combined list of all filter options for search suggestions
  final List<FilterOption> allSearchOptions = [
    ...serviceFilters,
    ...cityFilters,
    ...otherFilters,
  ];

  // Apply the theme to the search bar and results
  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor:
            kCardBackgroundColor, // White background for the search bar
        iconTheme: theme.iconTheme.copyWith(color: kDarkTextColor),
        titleTextStyle: const TextStyle(
          color: kDarkTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Exo2',
        ),
        elevation: 0, // No shadow for the AppBar
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: kMutedTextColor, fontFamily: 'Exo2'),
        border: InputBorder.none, // Remove the underline
      ),
      scaffoldBackgroundColor:
          kLightBackgroundColor, // Light background for the body
    );
  }

  // Action to clear the search query
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(CupertinoIcons.clear_thick_circled),
        color: kMutedTextColor,
        onPressed: () {
          if (query.isEmpty) {
            close(context, ''); // Close the delegate if the query is empty
          } else {
            query = ''; // Clear the query
          }
        },
      ),
    ];
  }

  // Leading icon (back button)
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(CupertinoIcons.back),
      color: kDarkTextColor,
      onPressed: () {
        close(context, ''); // Return an empty string when closing
      },
    );
  }

  // The main widget to display search results after submission
  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          "Type a service (e.g., 'Doctor') to search.",
          style: TextStyle(color: kMutedTextColor, fontFamily: 'Exo2'),
        ),
      );
    }

    final List<FilterOption> results =
        allSearchOptions
            .where(
              (option) =>
                  option.label.toLowerCase().contains(query.toLowerCase()) ||
                  option.value.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    return Container(
      color: kLightBackgroundColor,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          return ListTile(
            leading: Icon(
              // Simple icon logic based on the value to differentiate
              result.value.contains('electrician') ||
                      result.value.contains('plumber') ||
                      result.value.contains('handyman')
                  ? CupertinoIcons.wrench_fill
                  : result.value.contains('doctor')
                  ? CupertinoIcons.bandage_fill
                  : result.value.contains('tutor')
                  ? CupertinoIcons.book_fill
                  : CupertinoIcons.location_solid,
              color: kPrimaryBlue,
            ),
            title: Text(
              result.label,
              style: const TextStyle(color: kDarkTextColor, fontFamily: 'Exo2'),
            ),
            subtitle: Text(
              "Category: ${result.value.split('_')[0]}",
              style: TextStyle(
                color: kMutedTextColor.withOpacity(0.8),
                fontFamily: 'Exo2',
                fontSize: 12,
              ),
            ),
            onTap: () {
              // The search result can be selected and returned
              close(context, result.label);
              // In a real app, this would trigger the actual map search/filter
            },
          );
        },
      ),
    );
  }

  // Widget to display suggestions as the user types
  @override
  Widget buildSuggestions(BuildContext context) {
    final List<FilterOption> suggestions =
        allSearchOptions
            .where(
              (option) =>
                  option.label.toLowerCase().startsWith(query.toLowerCase()),
            )
            .toList();

    return Container(
      color: kLightBackgroundColor,
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            leading: const Icon(
              CupertinoIcons.search,
              color: kMutedTextColor,
              size: 20,
            ),
            title: Text(
              suggestion.label,
              style: const TextStyle(color: kDarkTextColor, fontFamily: 'Exo2'),
            ),
            onTap: () {
              // Update the query with the suggestion's label and show results
              query = suggestion.label;
              showResults(context);
            },
          );
        },
      ),
    );
  }
}
