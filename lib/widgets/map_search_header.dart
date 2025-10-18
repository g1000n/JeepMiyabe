import 'package:flutter/material.dart';

/// The custom search bar for the top of the map screen (Settings icon removed).
class MapSearchHeader extends StatefulWidget {
  final Color primaryColor;
  final List<String> nodeNames;
  final Function(String query) onSearch;

  const MapSearchHeader({
    super.key,
    required this.primaryColor,
    required this.nodeNames,
    required this.onSearch,
  });

  @override
  State<MapSearchHeader> createState() => _MapSearchHeaderState();
}

class _MapSearchHeaderState extends State<MapSearchHeader> {
  final TextEditingController _controller = TextEditingController();
  String? _suggestion;

  // Define a consistent text style for both input and suggestion
  static const TextStyle _baseTextStyle = TextStyle(
    fontSize: 14.0,
  );

  @override
  void initState() {
    super.initState();
    // ✅ Keep: Listener to ensure suggestions update as user types
    _controller.addListener(_updateSuggestion);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSuggestion);
    _controller.dispose();
    super.dispose();
  }

  /// Finds the first node name that starts with the current text input.
  void _updateSuggestion() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestion = null;
      });
      return;
    }

    // Find the first name that starts with the query (case-insensitive)
    final foundName = widget.nodeNames.firstWhere(
      (name) => name.toLowerCase().startsWith(query.toLowerCase()),
      orElse: () => '',
    );

    setState(() {
      // If a match is found and it's longer than the query, set the suggestion
      if (foundName.isNotEmpty && foundName.length > query.length) {
        _suggestion = foundName;
      } else {
        _suggestion = null;
      }
    });
  }

  /// Handler for when the user taps on the search bar or hits enter.
  void _handleSearch() {
    String finalQuery = _controller.text.trim();

    // If there's a suggestion and the user hits enter, use the full suggestion.
    if (_suggestion != null && finalQuery.isNotEmpty && _suggestion!.toLowerCase().startsWith(finalQuery.toLowerCase())) {
      // Use the full suggestion text to replace the input
      finalQuery = _suggestion!;
      _controller.text = finalQuery;
      _controller.selection =
          TextSelection.fromPosition(TextPosition(offset: finalQuery.length));
    }

    widget.onSearch(finalQuery);
    // Remove focus to hide the keyboard
    FocusManager.instance.primaryFocus?.unfocus();
    // Recalculate suggestion after handling search
    // This is needed to clear the suggestion if the search used the full text
    _updateSuggestion(); 
  }

  /// Helper function to use the full suggestion and then execute search.
  void _acceptSuggestionAndSearch() {
    if (_suggestion != null) {
      // Set the full text into the controller
      _controller.text = _suggestion!;
      // Move cursor to the end
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _suggestion!.length));
      // Execute the search logic
      _handleSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Text style for the suggestion (light, faint text)
    final TextStyle suggestionStyle = _baseTextStyle.copyWith(
      color: Colors.grey.shade400, // Very faint color
    );

    // Style for the user's input (normal color)
    final TextStyle inputStyle = _baseTextStyle.copyWith(
      color: Colors.black,
    );

    return Row(
      children: [
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.0),
              border: Border.all(color: widget.primaryColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // 1. The Faint Suggestion Text (Full suggested word)
                      // This appears *behind* the TextField.
                      if (_suggestion != null && _controller.text.isNotEmpty)
                        Text(
                          _suggestion!,
                          style: suggestionStyle,
                          overflow: TextOverflow.ellipsis,
                        ),

                      // 2. The User's Actual Text Field
                      TextField(
                        controller: _controller,
                        // Triggers when user hits "Enter" or "Done" on the keyboard
                        onSubmitted: (value) => _handleSearch(), 
                        style: inputStyle,
                        decoration: InputDecoration(
                          hintText: 'Search for a jeepney stop...',
                          hintStyle: _baseTextStyle.copyWith(
                              color: Colors.grey.shade600),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          
                          // Ensures the TextField background is fully transparent
                          filled: true,
                          fillColor: Colors.transparent, 

                          // Prevent hint text from fading in when suggestion is present
                          hintFadeDuration:
                              _suggestion != null ? Duration.zero : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Explicit button to accept the suggestion and search
                if (_suggestion != null && _controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: _acceptSuggestionAndSearch, 
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.arrow_forward,
                          color: widget.primaryColor, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ),

      ],
    );
  }
}