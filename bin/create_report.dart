library create_report;

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:io';
import 'package:coverage/src/devtools.dart';
import 'package:coverage/src/util.dart';

import 'collect_coverage.dart' as collect_coverage;

import 'format_coverage.dart' as format_coverage;

void main(List<String> arguments) {
//dart --enable-vm-service --pause-isolates-on-exit test/all.dart
//dart bin/collect_coverage.dart --port=8181 -o /Users/adam.singer/dart/chrome.dart/coverage.json --resume-isolates
//dart bin/format_coverage.dart -s /Applications/dart/dart-sdk -p /Users/adam.singer/dart/chrome.dart/packages/ -i /Users/adam.singer/dart/chrome.dart/coverage.json -r  -v

  launchUnittest([]);
  collect_coverage_main(['--port=8181',
                         '-o',
                         '/Users/adam.singer/dart/chrome.dart/coverage.json',
                         //'--resume-isolates'
                         ]).then((_) {
  format_coverage.main(['-s',
                        '/Applications/dart/dart-sdk',
                        '-p',
                        '/Users/adam.singer/dart/chrome.dart/packages/',
                        '-i', '/Users/adam.singer/dart/chrome.dart/coverage.json',
                        '-r',
                        '-v']);
  });
}

Future collect_coverage_main(List<String> arguments) {
  var options = collect_coverage.parseArgs(arguments);
  onTimeout() {
    var timeout = options.timeout.inSeconds;
    print('Failed to collect coverage within ${timeout}s');
    exit(1);
  }
  Future connected = retry(() =>
      Observatory.connect(options.host, options.port), collect_coverage.RETRY_INTERVAL);
  if (options.timeout != null) {
    connected.timeout(options.timeout, onTimeout: onTimeout);
  }
  return connected.then((observatory) {
    Future ready = options.waitPaused
        ? collect_coverage.waitIsolatesPaused(observatory)
        : new Future.value();
    if (options.timeout != null) {
      ready.timeout(options.timeout, onTimeout: onTimeout);
    }
    return ready.then((_) => collect_coverage.getAllCoverage(observatory))
        .then(JSON.encode)
        .then(options.out.write)
        .then((_) => options.out.close())
        .then((_) => options.resume ? collect_coverage.resumeIsolates(observatory) : null)
        .then((_) => observatory.close());
  });
}

void launchUnittest(args) {

}
