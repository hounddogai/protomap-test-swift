import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationScoresForSnapshot(_ items: [AuthorizationScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveDenialSnapshotsFromScore(_ items: [AuthorizationScore]) -> [DenialSnapshot] {
        var out: [DenialSnapshot] = []
        for item in items {
            let derived = newDenialSnapshot(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceDenialSnapshot(_ item: DenialSnapshot) -> String {
        return tieredAuthorizationCycleBucket(item.effectiveVolume())
    }
}
