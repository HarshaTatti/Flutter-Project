// // Enhanced chatbot response formatting methods
// // Place these in chatbot_service.dart

// /// Build response from single source with prominent file name
// String buildSingleSourceResponse(_CandidateAnswer answer) {
//   final buffer = StringBuffer();

//   // Show source file name at the top
//   buffer.writeln('📄 From: ${answer.documentName}\n');

//   // Show the answer
//   final concise = answer.text.length > 400
//       ? '${answer.text.substring(0, 400).trim()}…'
//       : answer.text;

//   buffer.writeln(concise);

//   // Source transparency with visual confidence bar
//   final confidencePercent = (answer.confidence * 100).toStringAsFixed(0);
//   final bars = '█' * ((answer.confidence * 10).round()).clamp(0, 10);

//   buffer.writeln('\n\n━━━━━━━━━━━━━━━━━━━━');
//   buffer.writeln('📚 Source: ${answer.documentName}');
//   buffer.writeln('🎯 Confidence: $bars $confidencePercent%');

//   return buffer.toString().trim();
// }

// /// Build response from multiple sources with file names
// String buildMultiSourceResponse(List<_CandidateAnswer> sources, String query) {
//   final buffer = StringBuffer();
//   final primarySource = sources.first;

//   // Show primary source file name at the top
//   buffer.writeln('📄 Primary Source: ${primarySource.documentName}\n');

//   // Main answer from best source
//   final mainAnswer = primarySource.text.length > 350
//       ? '${primarySource.text.substring(0, 350).trim()}…'
//       : primarySource.text;

//   buffer.writeln(mainAnswer);

//   // Add supporting information from other sources if different
//   var addedSupporting = false;
//   for (var i = 1; i < sources.length; i++) {
//     final supportingText = sources[i].text;
//     // Only add if it contains new information
//     if (!isTooSimilar(mainAnswer, supportingText)) {
//       if (!addedSupporting) {
//         buffer.writeln('\n\n💡 Additional Information:');
//         addedSupporting = true;
//       }
//       final snippet = supportingText.length > 200
//           ? '${supportingText.substring(0, 200).trim()}…'
//           : supportingText;
//       buffer.writeln('\n📄 ${sources[i].documentName}:');
//       buffer.writeln(snippet);
//     }
//   }

//   // Source transparency section
//   if (sources.length > 1) {
//     buffer.writeln('\n\n━━━━━━━━━━━━━━━━━━━━');
//     buffer.writeln('📚 All Relevant Sources (${sources.length}):');
//     for (var i = 0; i < sources.length; i++) {
//       final source = sources[i];
//       final percentage = (source.confidence * 100).toStringAsFixed(0);
//       final bars = '█' * ((source.confidence * 10).round()).clamp(0, 10);
//       buffer.writeln(
//         '  ${i + 1}. ${source.documentName}\n     $bars $percentage%',
//       );
//     }
//   }

//   // Overall confidence
//   final avgConfidence =
//       sources.map((s) => s.confidence).reduce((a, b) => a + b) / sources.length;
//   final confidencePercent = (avgConfidence * 100).toStringAsFixed(0);
//   buffer.writeln('\n🎯 Overall Confidence: $confidencePercent%');

//   return buffer.toString().trim();
// }

// /// Check if two texts are too similar
// bool isTooSimilar(String text1, String text2) {
//   final words1 = text1.toLowerCase().split(RegExp(r'\W+'));
//   final words2 = text2.toLowerCase().split(RegExp(r'\W+'));

//   final set1 = Set<String>.from(words1.where((w) => w.length > 3));
//   final set2 = Set<String>.from(words2.where((w) => w.length > 3));

//   if (set1.isEmpty || set2.isEmpty) return true;

//   final intersection = set1.intersection(set2).length;
//   final union = set1.union(set2).length;

//   // If more than 70% similar, consider redundant
//   return (intersection / union) > 0.7;
// }
