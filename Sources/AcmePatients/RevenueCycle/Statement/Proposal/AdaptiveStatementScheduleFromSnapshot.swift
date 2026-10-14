import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeScheduledAuthorizationSnapshotsForSchedule(_ items: [ScheduledAuthorizationSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveAdaptiveStatementSchedulesFromSnapshot(_ items: [ScheduledAuthorizationSnapshot]) -> [AdaptiveStatementSchedule] {
        var out: [AdaptiveStatementSchedule] = []
        for item in items {
            let derived = newAdaptiveStatementSchedule(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreAdaptiveStatementSchedule(_ item: AdaptiveStatementSchedule) -> String {
        return normalizeAuthorizationManifestCode(item.code)
    }
}
