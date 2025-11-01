import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class InjuryTrackerService {
  // API Configuration - Choose ONE based on where you're running the app:
  
  // For Android Emulator (10.0.2.2 is the emulator's alias for localhost):
  // static const String baseUrl = 'http://10.0.2.2:8000';
  
  // For iOS Simulator or Chrome Web:
  static const String baseUrl = 'http://192.168.8.100:8000';
  
  // For Physical Device (replace with your computer's local IP from ipconfig):
  // static const String baseUrl = 'http://192.168.1.100:8000';
  
  final String userId;
  
  InjuryTrackerService({required this.userId});
  
  /// Analyze wound image and get severity with recommendations
  Future<Map<String, dynamic>> analyzeWound(File imageFile) async {
    try {
      print('🔍 Starting wound analysis...');
      print('📁 Image path: ${imageFile.path}');
      print('📊 Image size: ${await imageFile.length()} bytes');
      
      final url = Uri.parse('$baseUrl/api/v1/analyze-wound');
      print('🌐 API endpoint: $url');
      
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $userId';
      
      // Detect MIME type and add image file with proper content type
      final mimeType = lookupMimeType(imageFile.path);
      print('🎨 Detected MIME type: $mimeType');
      
      if (mimeType == null) {
        throw Exception('Could not determine file type. Please use a valid image file.');
      }
      
      final mimeTypeSplit = mimeType.split('/');
      if (mimeTypeSplit.length != 2) {
        throw Exception('Invalid MIME type format: $mimeType');
      }
      
      // Add file with explicit content type
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType(mimeTypeSplit[0], mimeTypeSplit[1]),
        ),
      );
      
      print('📤 Sending multipart request...');
      print('📋 Content-Type: ${mimeTypeSplit[0]}/${mimeTypeSplit[1]}');
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body length: ${response.body.length} chars');
      
      if (response.statusCode == 200) {
        print('✅ Analysis successful');
        return json.decode(response.body);
      } else {
        print('❌ Analysis failed');
        print('Error body: ${response.body}');
        throw Exception('Failed to analyze wound: ${response.body}');
      }
    } catch (e) {
      print('💥 Exception during analysis: $e');
      throw Exception('Error analyzing wound: $e');
    }
  }
  
  /// Get all injury records for user
  Future<List<dynamic>> getInjuries({int limit = 50}) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/injuries?limit=$limit');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userId',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get injuries: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting injuries: $e');
    }
  }
  
  /// Get specific injury details
  Future<Map<String, dynamic>> getInjuryDetails(String injuryId) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/injuries/$injuryId');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userId',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get injury details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting injury details: $e');
    }
  }
  
  /// Update injury status
  Future<Map<String, dynamic>> updateInjuryStatus(
    String injuryId,
    String status, {
    String? notes,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/injuries/$injuryId/status');
      
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $userId',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'status': status,
          if (notes != null) 'notes': notes,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }
  
  /// Delete injury record
  Future<Map<String, dynamic>> deleteInjury(String injuryId) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/injuries/$injuryId');
      
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $userId',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete injury: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting injury: $e');
    }
  }
  
  /// Get user statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/statistics');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userId',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get statistics: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting statistics: $e');
    }
  }
}
