import 'package:flutter/material.dart';

class TagsSection extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;

  const TagsSection({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  @override
  State<TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends State<TagsSection> {
  final List<String> _availableTags = [
    'Quick Service',
    '24/7 Available',
    'Emergency',
    'Weekend Available',
    'Free Estimate',
    'Insured',
    'Certified',
    'Eco-Friendly',
    'Same Day Service',
    'Guaranteed Work'
  ];

  final Color _primaryColor = Color(0xFF2563EB);
  final Color _successColor = Color(0xFF059669);
  final Color _textPrimary = Color(0xFF1E293B);
  final Color _textSecondary = Color(0xFF64748B);
  final Color _borderColor = Color(0xFFE2E8F0);

  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer_rounded,
                size: 20,
                color: _primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Features',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select features that describe your service',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTagChip(String tag, bool isSelected) {
    return GestureDetector(
      onTap: () {
        final newTags = List<String>.from(widget.selectedTags);
        if (isSelected) {
          newTags.remove(tag);
        } else {
          newTags.add(tag);
        }
        widget.onTagsChanged(newTags);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryColor : _borderColor,
            width: 1.5,
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : _textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTagsIndicator() {
    if (widget.selectedTags.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 20, color: _textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No features selected yet',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _successColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: _successColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Features (${widget.selectedTags.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _successColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.selectedTags.join(', '),
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),

        // Tags Grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableTags.map((tag) {
            final isSelected = widget.selectedTags.contains(tag);
            return _buildTagChip(tag, isSelected);
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Selection Indicator
        _buildSelectedTagsIndicator(),

        // Help Text
        Container(
          margin: const EdgeInsets.only(top: 12),
          child: Text(
            'Tip: Select features that make your service stand out',
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
