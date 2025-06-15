import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../domain/models/note.dart';
import '../services/auth_service.dart';

class NoteRemoteDataSource {
  final String baseUrl = 'https://noterocr.netlify.app/.netlify/functions';
  final AuthService _authService;

  NoteRemoteDataSource(this._authService);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getIdToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    debugPrint('Request headers: $headers');
    return headers;
  }

  Future<List<Note>> getNotes() async {
    try {
      debugPrint('Fetching notes from: $baseUrl/get-notes');
      final headers = await _getHeaders();
      debugPrint('Making GET request to $baseUrl/get-notes with headers: $headers');
      final response = await http.get(
        Uri.parse('$baseUrl/get-notes'),
        headers: headers,
      );
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> notesJson = data['notes'] as List<dynamic>;
        return notesJson.map((json) => Note.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching notes: $e');
      throw Exception('Failed to load notes: $e');
    }
  }

  Future<Note> getNote(String id) async {
    try {
      debugPrint('Fetching note from: $baseUrl/notes/$id');
      final headers = await _getHeaders();
      debugPrint('Making GET request to $baseUrl/notes/$id with headers: $headers');
      final response = await http.get(
        Uri.parse('$baseUrl/notes/$id'),
        headers: headers,
      );
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return Note.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load note');
      }
    } catch (e) {
      debugPrint('Error fetching note: $e');
      throw Exception('Failed to load note: $e');
    }
  }

  Future<Note> createNote(String text, {String? imageUrl}) async {
    try {
      debugPrint('Creating note at: $baseUrl/notes');
      final headers = await _getHeaders();
      debugPrint('Making POST request to $baseUrl/notes with headers: $headers');
      final response = await http.post(
        Uri.parse('$baseUrl/notes'),
        headers: headers,
        body: json.encode({
          'text': text,
          'image_url': imageUrl,
        }),
      );
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        return Note.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create note');
      }
    } catch (e) {
      debugPrint('Error creating note: $e');
      throw Exception('Failed to create note: $e');
    }
  }

  Future<void> updateNote(String id, String rawText) async {
    try {
      final headers = await _getHeaders();
      debugPrint('Making PUT request to $baseUrl/update-note with headers: $headers');
      final response = await http.put(
        Uri.parse('$baseUrl/update-note'),
        headers: headers,
        body: json.encode({
          'id': id,
          'rawText': rawText,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update note: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating note: $e');
      throw Exception('Failed to update note: $e');
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      debugPrint('Deleting note at: $baseUrl/notes/$id');
      final headers = await _getHeaders();
      debugPrint('Making DELETE request to $baseUrl/notes/$id with headers: $headers');
      final response = await http.delete(
        Uri.parse('$baseUrl/notes/$id'),
        headers: headers,
      );
      debugPrint('Response status code: ${response.statusCode}');
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete note');
      }
    } catch (e) {
      debugPrint('Error deleting note: $e');
      throw Exception('Failed to delete note: $e');
    }
  }

  Future<String> processImage(File imageFile) async {
    try {
      final headers = await _getHeaders();
      debugPrint('Making POST request to $baseUrl/process-image with headers: $headers');
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/process-image'),
      );

      // Add headers to the request
      request.headers.addAll(headers);

      // Add the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['text'] ?? 'No text found in image';
      } else {
        throw Exception('Failed to process image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      throw Exception('Error processing image: $e');
    }
  }

  Future<String> processPDF(File pdfFile) async {
    try {
      final headers = await _getHeaders();
      debugPrint('Making POST request to $baseUrl/process-pdf with headers: $headers');
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/process-pdf'),
      );

      // Add headers to the request
      request.headers.addAll(headers);

      // Add the PDF file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'pdf',
          pdfFile.path,
        ),
      );

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['text'] ?? 'No text found in PDF';
      } else {
        throw Exception('Failed to process PDF: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error processing PDF: $e');
      throw Exception('Error processing PDF: $e');
    }
  }
} 