import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/search_filter.dart';
import '../../../providers/listings_provider.dart';

/// Dialog for configuring search filters
class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late TextEditingController _areaController;
  late SearchFilter _tempFilter;

  @override
  void initState() {
    super.initState();
    final currentFilter = context.read<ListingsProvider>().currentFilter;
    _tempFilter = currentFilter.copyWith();
    _areaController = TextEditingController(text: _tempFilter.area);
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  void _saveAndRefresh() {
    final updatedFilter = _tempFilter.copyWith(
      area: _areaController.text.trim().isNotEmpty
          ? _areaController.text.trim()
          : 'soest',
    );
    context.read<ListingsProvider>().updateFilter(updatedFilter);
    Navigator.of(context).pop();
  }

  void _discard() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Filters'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Area filter (enabled)
            const Text(
              'Area',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _areaController,
              decoration: const InputDecoration(
                hintText: 'e.g., soest, amsterdam, utrecht',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Object Type filter (disabled)
            const Text(
              'Object Type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: false,
              controller: TextEditingController(text: _tempFilter.objectType),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 16),

            // Publication Date filter (disabled)
            const Text(
              'Publication Date (days)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: false,
              controller:
                  TextEditingController(text: _tempFilter.publicationDate),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 16),

            // Sort Order filter (disabled)
            const Text(
              'Sort Order',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: false,
              controller: TextEditingController(text: _tempFilter.sortOrder),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Discard button
        TextButton(
          onPressed: _discard,
          child: const Text(
            'Discard',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        // Save and refresh button
        ElevatedButton(
          onPressed: _saveAndRefresh,
          child: const Text('Save & Refresh'),
        ),
      ],
    );
  }
}
