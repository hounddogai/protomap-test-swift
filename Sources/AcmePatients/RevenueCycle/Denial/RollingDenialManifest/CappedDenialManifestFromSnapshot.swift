import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeCappedStatementSnapshotsForManifest(_ items: [CappedStatementSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedDenialManifestsFromSnapshot(_ items: [CappedStatementSnapshot]) -> [CappedDenialManifest] {
        var out: [CappedDenialManifest] = []
        for item in items {
            let derived = newCappedDenialManifest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveCappedDenialManifest(_ item: CappedDenialManifest) -> String {
        return classifyRollingStatementException(item.weightedValue())
    }
}
