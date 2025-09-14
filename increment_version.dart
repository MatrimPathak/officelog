#!/usr/bin/env dart

import 'dart:io';

/// Script to automatically increment version code and version name in pubspec.yaml
/// Usage: dart increment_version.dart [patch|minor|major]
/// Default: patch

void main(List<String> args) {
  final incrementType = args.isNotEmpty ? args[0] : 'patch';

  if (!['patch', 'minor', 'major'].contains(incrementType)) {
    print('Error: Invalid increment type. Use: patch, minor, or major');
    exit(1);
  }

  try {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print('Error: pubspec.yaml not found');
      exit(1);
    }

    final content = pubspecFile.readAsStringSync();
    final versionRegex = RegExp(
      r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)$',
      multiLine: true,
    );
    final match = versionRegex.firstMatch(content);

    if (match == null) {
      print('Error: Could not parse version from pubspec.yaml');
      exit(1);
    }

    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3)!);
    final buildNumber = int.parse(match.group(4)!);

    String newVersion;
    int newBuildNumber = buildNumber + 1;

    switch (incrementType) {
      case 'major':
        newVersion = '${major + 1}.0.0';
        break;
      case 'minor':
        newVersion = '$major.${minor + 1}.0';
        break;
      case 'patch':
      default:
        newVersion = '$major.$minor.${patch + 1}';
        break;
    }

    final newVersionLine = 'version: $newVersion+$newBuildNumber';
    final updatedContent = content.replaceFirst(versionRegex, newVersionLine);

    pubspecFile.writeAsStringSync(updatedContent);

    print('✅ Version updated successfully!');
    print('📱 New version: $newVersion');
    print('🔢 New build number: $newBuildNumber');
    print('📝 Updated pubspec.yaml');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
