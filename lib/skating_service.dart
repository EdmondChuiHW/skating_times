import 'dart:async';

class ImmutableSkatingSession {
  final DateTime startTime;
  final DateTime endTime;

  final String displayTitle;
  final String locationDisplayName;

  final String locationAddress;

  const ImmutableSkatingSession(this.startTime,
      this.endTime,
      this.displayTitle,
      this.locationDisplayName,
      this.locationAddress,);
}

abstract class SkatingService {
  Future<Iterable<ImmutableSkatingSession>> getSessions({
    num maxNumberOfSessions,
    String sortBy,
    DateTime maxTime
  });
}