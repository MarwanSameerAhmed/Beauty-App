import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glamify/view/search_results_page.dart';
import 'package:glamify/controller/product_service.dart';
import 'package:glamify/utils/responsive_helper.dart';

class Searchbar extends StatefulWidget {
  const Searchbar({super.key});

  @override
  _SearchbarState createState() => _SearchbarState();
}

class _SearchbarState extends State<Searchbar> {
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  final FocusNode _focusNode = FocusNode();

  List<String> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _getSuggestions(_searchController.text);
    });
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  Future<void> _getSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    try {
      final suggestions = await _productService.getSearchSuggestions(query);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty && _focusNode.hasFocus;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _performSearch([String? searchQuery]) {
    final query = searchQuery ?? _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _showSuggestions = false;
      });
      _focusNode.unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(searchQuery: query),
        ),
      );
    }
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    // تهيئة الـ responsive helper
    ResponsiveHelper.init(context);
    
    final horizontalPadding = ResponsiveHelper.horizontalPadding;
    final borderRadius = ResponsiveHelper.borderRadius;
    final iconSize = ResponsiveHelper.iconSize;
    final bodyFontSize = ResponsiveHelper.bodyFontSize;
    final smallFontSize = ResponsiveHelper.smallFontSize;
    final buttonSize = ResponsiveHelper.isMobile ? 50.0 : 58.0;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding + 4, 0.0, horizontalPadding + 4, horizontalPadding),
      child: Column(
        children: [
          Row(
            children: [
              // زر البحث
              Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF52002C), Color(0xFF942A59)],
                    stops: [0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: IconButton(
                  icon: Icon(Icons.search, color: Colors.white, size: iconSize),
                  onPressed: _performSearch,
                ),
              ),

              SizedBox(width: horizontalPadding * 0.75),
              
              // حقل البحث
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                    child: SizedBox(
                      height: buttonSize,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        textDirection: TextDirection.rtl,
                        onSubmitted: (value) => _performSearch(),
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: bodyFontSize,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن منتج...',
                          hintTextDirection: TextDirection.rtl,
                          hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontFamily: 'Tajawal',
                            fontSize: bodyFontSize,
                          ),
                          filled: true,
                          fillColor: const Color.fromARGB(255, 216, 213, 213).withOpacity(0.2),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: ResponsiveHelper.isMobile ? 12 : 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: Colors.black.withOpacity(0.4),
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.6),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // القائمة المنسدلة للاقتراحات
          if (_showSuggestions && _suggestions.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 8, left: buttonSize + horizontalPadding * 0.75),
              constraints: BoxConstraints(maxHeight: ResponsiveHelper.isMobile ? 200 : 250),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9D5D3).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.isMobile ? 8 : 10),
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.2),
                      indent: horizontalPadding,
                      endIndent: horizontalPadding,
                    ),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return InkWell(
                        onTap: () => _selectSuggestion(suggestion),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: ResponsiveHelper.isMobile ? 12 : 14,
                          ),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: TextStyle(
                                    fontSize: smallFontSize + 2,
                                    color: Colors.black87,
                                    fontFamily: 'Tajawal',
                                  ),
                                  textDirection: TextDirection.rtl,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: horizontalPadding * 0.75),
                              Icon(
                                Icons.search,
                                size: iconSize * 0.8,
                                color: Colors.black.withOpacity(0.6),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

