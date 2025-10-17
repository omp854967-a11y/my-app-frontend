import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vendor_service.dart';
import '../services/my_services_screen.dart';

class VendorSettingsPage extends StatefulWidget {
  const VendorSettingsPage({super.key});

  @override
  State<VendorSettingsPage> createState() => _VendorSettingsPageState();
}

class _VendorSettingsPageState extends State<VendorSettingsPage> {
  bool _saving = false;
  
  // Vendor profile data
  String _businessName = 'My Business';
  String _vendorBio = 'No bio added yet';
  String? _vendorId;
  Uint8List? _vendorAvatarBytes;
  List<Map<String, String>> _services = [];
  
  final VendorService _vendorService = VendorService();

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load vendor data
    final vendorBio = prefs.getString('vendor_bio');
    final businessName = prefs.getString('vendor_business_name');
    final vendorAvatarBase64 = prefs.getString('vendor_avatar');
    final vendorId = prefs.getString('vendor_id');
    final servicesJson = prefs.getString('vendor_services');
    
    setState(() {
      if (vendorBio != null && vendorBio.isNotEmpty) _vendorBio = vendorBio;
      if (businessName != null && businessName.isNotEmpty) _businessName = businessName;
      if (vendorAvatarBase64 != null && vendorAvatarBase64.isNotEmpty) {
        _vendorAvatarBytes = base64Decode(vendorAvatarBase64);
      }
      if (vendorId != null) _vendorId = vendorId;
      
      // Load services
      if (servicesJson != null && servicesJson.isNotEmpty) {
        try {
          final List<dynamic> servicesList = jsonDecode(servicesJson);
          _services = servicesList.map((service) => Map<String, String>.from(service)).toList();
        } catch (e) {
          _services = [];
        }
      }
    });
  }

  // Vendor profile edit functions
  Future<void> _editBusinessName() async {
    final controller = TextEditingController(text: _businessName);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Business Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLength: 50,
                decoration: const InputDecoration(
                  hintText: 'Enter your business name',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final newName = controller.text.trim();
                      if (newName.isNotEmpty) {
                        setState(() => _saving = true);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('vendor_business_name', newName);
                        setState(() {
                          _businessName = newName;
                          _saving = false;
                        });
                        if (mounted) {
                          Navigator.pop(ctx);
                          Navigator.pop(context, true); // Return true to indicate data was updated
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Business name updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editVendorBio() async {
    final controller = TextEditingController(text: _vendorBio);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Business Bio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 150,
                decoration: const InputDecoration(
                  hintText: 'Tell people about your business...',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final newBio = controller.text.trim();
                      if (newBio.isNotEmpty) {
                        setState(() => _saving = true);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('vendor_bio', newBio);
                        setState(() {
                          _vendorBio = newBio;
                          _saving = false;
                        });
                        if (mounted) {
                          Navigator.pop(ctx);
                          Navigator.pop(context, true); // Return true to indicate data was updated
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bio updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickVendorAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vendor_avatar', base64Image);
      
      setState(() {
        _vendorAvatarBytes = bytes;
      });
      
      Navigator.pop(context, true); // Return true to indicate data was updated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Service management functions
  Future<void> _addService() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final price = priceController.text.trim();
                      final description = descriptionController.text.trim();
                      
                      if (name.isNotEmpty && price.isNotEmpty) {
                        final newService = {
                          'name': name,
                          'price': price,
                          'description': description,
                        };
                        
                        setState(() {
                          _services.add(newService);
                        });
                        
                        await _saveServices();
                        
                        if (mounted) Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Service added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
                    child: const Text('Add Service'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveServices() async {
    final prefs = await SharedPreferences.getInstance();
    final servicesJson = jsonEncode(_services);
    await prefs.setString('vendor_services', servicesJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Vendor Settings'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Edit Section
            _buildProfileEditSection(),
            const SizedBox(height: 24),
            
            // My Services Section
            _buildMyServicesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileEditSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Edit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 16),
          
          // Profile Picture
          Center(
            child: GestureDetector(
              onTap: _pickVendorAvatar,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  image: _vendorAvatarBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_vendorAvatarBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _vendorAvatarBytes == null
                    ? const Icon(Icons.camera_alt, size: 30, color: Colors.grey)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Business Name
          _buildEditItem(
            'Business Name',
            _businessName,
            Icons.business,
            _editBusinessName,
          ),
          const SizedBox(height: 12),
          
          // Business Bio
          _buildEditItem(
            'Business Bio',
            _vendorBio,
            Icons.description,
            _editVendorBio,
          ),
        ],
      ),
    );
  }

  Widget _buildMyServicesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B35),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addService,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_services.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Column(
                children: [
                  Icon(Icons.work_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No services added yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add your first service to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
                return _buildServiceCard(service, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEditItem(String title, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF6B35), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, String> service, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.work,
                  color: Color(0xFFFF6B35),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'] ?? 'Service Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹${service['price'] ?? '0'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (service['description']?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              service['description'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}