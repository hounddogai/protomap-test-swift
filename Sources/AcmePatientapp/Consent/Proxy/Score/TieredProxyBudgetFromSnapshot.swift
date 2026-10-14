import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessSnapshotsForBudget(_ items: [WitnessSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveTieredProxyBudgetsFromSnapshot(_ items: [WitnessSnapshot]) -> [TieredProxyBudget] {
        var out: [TieredProxyBudget] = []
        for item in items {
            let derived = newTieredProxyBudget(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateTieredProxyBudget(_ item: TieredProxyBudget) -> String {
        return witnessSnapshotBucket(item.projectedTotal())
    }
}
