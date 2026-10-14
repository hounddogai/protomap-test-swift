import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertSummariesForTarget(_ items: [AlertSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRoundingTargetsFromSummary(_ items: [AlertSummary]) -> [RoundingTarget] {
        var out: [RoundingTarget] = []
        for item in items {
            let derived = newRoundingTarget(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchRoundingTarget(_ item: RoundingTarget) -> String {
        return alertAllocationBucket(item.projectedVolume())
    }
}
