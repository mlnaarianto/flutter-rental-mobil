import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentalcar/layouts/app.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tglLahirController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();

  File? avatarImage;
  File? ktpImage;

  @override
  void initState() {
    super.initState();
    _loadGoogleUser();
  }

  void _loadGoogleUser() {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final user = googleSignIn.currentUser;

    if (user != null) {
      _namaController.text = user.displayName ?? '';
      _emailController.text = user.email;
    }
  }

  /// ================= AVATAR =================
  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() {
        avatarImage = File(image.path);
      });
    }
  }

  /// ================= DATE =================
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );

    if (picked != null) {
      _tglLahirController.text =
          "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  /// ================= KTP =================
  Future<void> _uploadKtp() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() {
        ktpImage = File(image.path);
      });
    }
  }

  /// ================= SAVE =================
  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      if (ktpImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto KTP wajib diupload")),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil disimpan")),
      );
    }
  }

  /// ================= BOTTOM NAVIGATION =================
  void _onBottomTap(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/booking');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/history');
    } else if (index == 3) {
      // sudah di profil
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: "Profil",
      currentIndex: 3, // sesuaikan dengan index profil di BottomNavigationBar
      onTap: _onBottomTap,
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= AVATAR =================
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        backgroundImage: avatarImage != null
                            ? FileImage(avatarImage!)
                            : const AssetImage("assets/anya.jpg")
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "Ketuk untuk ganti foto profil",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 25),

              /// ================= NAMA =================
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: "Nama",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Nama wajib diisi" : null,
              ),

              const SizedBox(height: 15),

              /// ================= EMAIL =================
              TextFormField(
                controller: _emailController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Email (Google)",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              /// ================= HP =================
              TextFormField(
                controller: _hpController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Nomor HP",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "Nomor HP wajib diisi";
                  }
                  if (v.length < 10) {
                    return "Nomor HP tidak valid";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              /// ================= TANGGAL LAHIR =================
              TextFormField(
                controller: _tglLahirController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: "Tanggal Lahir",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Tanggal lahir wajib diisi" : null,
              ),

              const SizedBox(height: 25),

              /// ================= KTP =================
              const Text(
                "Foto KTP",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _uploadKtp,
                child: AspectRatio(
                  aspectRatio: 1.6,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue, width: 1.5),
                      color: Colors.blue.withOpacity(0.05),
                    ),
                    child: ktpImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.credit_card,
                                  size: 48, color: Colors.blue),
                              SizedBox(height: 10),
                              Text(
                                "Upload Foto KTP",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Ketuk untuk memilih dari galeri",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              ktpImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// ================= SAVE =================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text("Simpan Profil"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
