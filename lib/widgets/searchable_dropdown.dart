import 'package:flutter/material.dart';

class SearchItem {
  final String id;
  final String name;

  SearchItem({required this.id, required this.name});
}

class SearchableDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final VoidCallback onTap;
  final String? Function(String?)? validator;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onTap,
    this.validator,
  });

  InputDecoration _glassInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        fontFamily: 'Tajawal',
        color: Colors.black.withOpacity(0.7),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(0.4),
          width: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(15),
              child: InputDecorator(
                decoration: _glassInputDecoration(label).copyWith(
                  errorText: state.errorText,
                  suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ),
                child: Text(
                  value ?? hint,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: value != null ? FontWeight.bold : FontWeight.normal,
                    color: value != null ? Colors.black : Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<String?> showSearchDialog({
    required BuildContext context,
    required String title,
    required List<SearchItem> items,
    String? selectedId,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: _SearchDialogWidget(
            title: title,
            items: items,
            selectedId: selectedId,
          ),
        );
      },
    );
  }
}

class _SearchDialogWidget extends StatefulWidget {
  final String title;
  final List<SearchItem> items;
  final String? selectedId;

  const _SearchDialogWidget({
    required this.title,
    required this.items,
    this.selectedId,
  });

  @override
  State<_SearchDialogWidget> createState() => _SearchDialogWidgetState();
}

class _SearchDialogWidgetState extends State<_SearchDialogWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<SearchItem> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    return widget.items
        .where((item) => item.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF52002C).withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF52002C),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 22),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF52002C).withOpacity(0.15),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ابحث...',
                        hintStyle: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: const Color(0xFF52002C).withOpacity(0.4),
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_filteredItems.length} نتيجة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد نتائج مطابقة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: _filteredItems.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item.id == widget.selectedId;
                        return ListTile(
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF52002C) : Colors.black87,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Color(0xFF52002C))
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: isSelected
                              ? const Color(0xFF52002C).withOpacity(0.05)
                              : Colors.transparent,
                          onTap: () => Navigator.pop(context, item.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
