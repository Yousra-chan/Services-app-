import 'package:flutter/material.dart';

class PriceSection extends StatelessWidget {
  final TextEditingController priceController;
  final String selectedPriceUnit;
  final List<String> priceUnits;
  final Function(String?) onPriceUnitChanged;

  const PriceSection({
    super.key,
    required this.priceController,
    required this.selectedPriceUnit,
    required this.priceUnits,
    required this.onPriceUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Color _primaryColor = Color(0xFF2563EB); // Professional blue
    final Color _accentColor = Color(0xFF059669); // Success green
    final Color _textPrimary = Color(0xFF1E293B); // Dark text
    final Color _textSecondary = Color(0xFF64748B); // Muted text
    final Color _borderColor = Color(0xFFE2E8F0); // Border color
    final Color _backgroundColor = Color(0xFFF8FAFC); // Light background

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
                  Icons.currency_exchange_rounded,
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
                      'Service Pricing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set your service price in Algerian Dinar (DZD)',
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

    Widget _buildPriceInput() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: priceController,
          decoration: InputDecoration(
            labelText: 'Price (DZD)',
            labelStyle: TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            hintText: '0.00',
            hintStyle: TextStyle(
              color: _textSecondary.withOpacity(0.6),
              fontSize: 16,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DZD',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 20,
                    color: _borderColor,
                  ),
                ],
              ),
            ),
          ),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the price';
            }
            final numericValue = double.tryParse(value);
            if (numericValue == null) {
              return 'Please enter a valid price';
            }
            if (numericValue <= 0) {
              return 'Price must be greater than zero';
            }
            if (numericValue > 1000000) {
              return 'Price is too high';
            }
            return null;
          },
        ),
      );
    }

    Widget _buildPriceUnitDropdown() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: selectedPriceUnit,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Billing Method',
            labelStyle: TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          items: priceUnits.map((unit) {
            String tooltipText = '';

            // Add descriptions for each billing method
            switch (unit) {
              case 'Per Hour':
                tooltipText = 'Charged based on hours worked';
                break;
              case 'Per Day':
                tooltipText = 'Charged based on days worked';
                break;
              case 'Per Service':
                tooltipText = 'Fixed price for the complete service';
                break;
              case 'Per Square Meter':
                tooltipText = 'Charged based on area size';
                break;
              case 'Per Item':
                tooltipText = 'Price per item or unit';
                break;
            }

            return DropdownMenuItem(
              value: unit,
              child: Tooltip(
                message: tooltipText,
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onChanged: onPriceUnitChanged,
          validator: (value) =>
              value == null ? 'Please select a billing method' : null,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: _primaryColor,
            size: 24,
          ),
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      );
    }

    Widget _buildPriceInfo() {
      if (priceController.text.isEmpty) return const SizedBox.shrink();

      final price = double.tryParse(priceController.text);
      if (price == null) return const SizedBox.shrink();

      String infoText = '';
      Color infoColor = _accentColor;

      switch (selectedPriceUnit) {
        case 'Per Hour':
          infoText = 'Hourly rate: ${price.toStringAsFixed(0)} DZD';
          break;
        case 'Per Day':
          infoText = 'Daily rate: ${price.toStringAsFixed(0)} DZD';
          break;
        case 'Per Service':
          infoText = 'Service price: ${price.toStringAsFixed(0)} DZD';
          break;
        case 'Per Square Meter':
          infoText = 'Per square meter: ${price.toStringAsFixed(0)} DZD';
          break;
        case 'Per Item':
          infoText = 'Per item: ${price.toStringAsFixed(0)} DZD';
          break;
      }

      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _accentColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: _accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              infoText,
              style: TextStyle(
                color: _accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildPriceChip(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),

        // Price Input Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceInput(),
                  _buildPriceInfo(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildPriceUnitDropdown(),
            ),
          ],
        ),
      ],
    );
  }
}
