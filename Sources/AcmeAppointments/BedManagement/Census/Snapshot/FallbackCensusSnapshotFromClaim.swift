import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeScheduledCleaningClaimsForSnapshot(_ items: [ScheduledCleaningClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveFallbackCensusSnapshotsFromClaim(_ items: [ScheduledCleaningClaim]) -> [FallbackCensusSnapshot] {
        var out: [FallbackCensusSnapshot] = []
        for item in items {
            let derived = newFallbackCensusSnapshot(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveFallbackCensusSnapshot(_ item: FallbackCensusSnapshot) -> String {
        return fallbackCleaningTemplateBucket(item.measuredValue())
    }
}
