import 'dart:io';
import 'dart:typed_data';

class OCRServiceStub {
  static final OCRServiceStub _instance = OCRServiceStub._internal();
  factory OCRServiceStub() => _instance;
  OCRServiceStub._internal();

  // Mock OCR functionality for MVP
  Future<String?> extractTextFromImage(File imageFile) async {
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));
    
    // Return mock OCR results based on filename or random content
    final fileName = imageFile.path.toLowerCase();
    
    if (fileName.contains('ticket')) {
      return _mockTicketText();
    } else if (fileName.contains('passport')) {
      return _mockPassportText();
    } else if (fileName.contains('license')) {
      return _mockLicenseText();
    } else if (fileName.contains('hotel')) {
      return _mockHotelText();
    } else {
      return _mockGenericText();
    }
  }

  Future<String?> extractTextFromBytes(Uint8List imageBytes) async {
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));
    
    // Return generic mock text for bytes
    return _mockGenericText();
  }

  Future<List<String>> extractTagsFromText(String text) async {
    // Simulate AI-powered tag extraction
    await Future.delayed(const Duration(milliseconds: 500));
    
    final lowercaseText = text.toLowerCase();
    final tags = <String>[];
    
    // Simple keyword matching for tag suggestions
    if (lowercaseText.contains('ticket') || lowercaseText.contains('booking')) {
      tags.add('#tickets');
    }
    if (lowercaseText.contains('passport') || lowercaseText.contains('visa')) {
      tags.add('#documents');
    }
    if (lowercaseText.contains('hotel') || lowercaseText.contains('accommodation')) {
      tags.add('#hotel');
    }
    if (lowercaseText.contains('flight') || lowercaseText.contains('airline')) {
      tags.add('#flight');
    }
    if (lowercaseText.contains('insurance')) {
      tags.add('#insurance');
    }
    if (lowercaseText.contains('medical') || lowercaseText.contains('medicine')) {
      tags.add('#medical');
    }
    if (lowercaseText.contains('emergency') || lowercaseText.contains('contact')) {
      tags.add('#emergency');
    }
    if (lowercaseText.contains('license') || lowercaseText.contains('driving')) {
      tags.add('#license');
    }
    
    return tags;
  }

  String _mockTicketText() {
    return '''
TRAVEL BOOKING CONFIRMATION
Booking Reference: ABC123XYZ
Passenger: John Doe
Date: September 5, 2025
From: Pune Junction (PUNE)
To: Goa (Margao - MAO)
Departure: 06:30 AM
Arrival: 11:45 AM
Seat: 2A, Window
Coach: S1
PNR: 1234567890
''';
  }

  String _mockPassportText() {
    return '''
PASSPORT
Republic of India
Passport No: J1234567
Surname: SHARMA
Given Names: AISHA
Date of Birth: 15/JAN/1995
Place of Birth: MUMBAI, INDIA
Date of Issue: 01/JAN/2020
Date of Expiry: 31/DEC/2029
Place of Issue: MUMBAI
''';
  }

  String _mockLicenseText() {
    return '''
DRIVING LICENCE
Transport Department
Government of Maharashtra
DL No: MH02 20190012345
Name: RAHUL KUMAR
S/D/W: SURESH KUMAR
DOB: 10/MAR/1992
Address: 123 Park Street
Mumbai, Maharashtra 400001
Valid Till: 09/MAR/2032
Vehicle Class: LMV, MCWG
''';
  }

  String _mockHotelText() {
    return '''
HOTEL RESERVATION CONFIRMATION
Sea View Resort & Spa
Confirmation Number: HSV789012
Guest Name: Aisha Sharma
Check-in: September 5, 2025
Check-out: September 9, 2025
Room Type: Deluxe Ocean View
Number of Guests: 2
Address: Beach Road, Calangute
Goa, India - 403516
Contact: +91-832-1234567
''';
  }

  String _mockGenericText() {
    return '''
Document scanned successfully.
Text extraction completed.
Please review and add appropriate tags.
This is a sample OCR result for demonstration purposes.
''';
  }

  // Feature availability flags
  bool get isOCRAvailable => true;
  bool get isTagExtractionAvailable => true;
  bool get isAdvancedOCRAvailable => false; // Premium feature
}


