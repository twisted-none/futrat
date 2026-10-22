/// Match display rules. A stale live flag never proves a final result.
const liveWindow = Duration(hours: 6);
const _liveStatuses = {
  'IN_PLAY',
  'LIVE',
  'HALF_TIME',
  'HALFTIME',
  'HT',
  'EXTRA_TIME',
  'ET',
  'PENALTIES',
  'PENALTY_SHOOTOUT',
};
final _clock = RegExp(r"^(?:\d{1,3}(?:\+\d{1,2})?'|\d{1,3}'\+\d{1,2}'?)$");

bool isLiveStatus(String status) =>
    _liveStatuses.contains(status) || _clock.hasMatch(status);

bool isLiveMatch(String status, DateTime kickoff, DateTime now) {
  final elapsed = now.difference(kickoff);
  return isLiveStatus(status) && !elapsed.isNegative && elapsed <= liveWindow;
}
