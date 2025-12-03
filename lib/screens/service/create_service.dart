import 'package:flutter/material.dart';
import 'package:myapp/screens/service/create_service_form.dart';
import 'package:provider/provider.dart';
import 'package:myapp/ViewModel/service_view_model.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  @override
  Widget build(BuildContext context) {
    final serviceViewModel = Provider.of<ServiceViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Create New Service',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF6366F1)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.help_outline_rounded,
                  size: 24, color: Color(0xFF6366F1)),
              onPressed: () {
                // Help action
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Header
          SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: 0.8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: CreateServiceForm(
              isLoading: serviceViewModel.isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
