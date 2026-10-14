import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledRevocationSnapshotsForBundle(_ items: [ScheduledRevocationSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRollingRevocationBundlesFromSnapshot(_ items: [ScheduledRevocationSnapshot]) -> [RollingRevocationBundle] {
        var out: [RollingRevocationBundle] = []
        for item in items {
            let derived = newRollingRevocationBundle(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRollingRevocationBundle(_ item: RollingRevocationBundle) -> Double {
        return scheduledRevocationExceptionWeight(3, active: true)
    }
}
