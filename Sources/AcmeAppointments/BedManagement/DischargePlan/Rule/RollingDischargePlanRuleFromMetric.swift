import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeFallbackTransferMetricsForRule(_ items: [FallbackTransferMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveRollingDischargePlanRulesFromMetric(_ items: [FallbackTransferMetric]) -> [RollingDischargePlanRule] {
        var out: [RollingDischargePlanRule] = []
        for item in items {
            let derived = newRollingDischargePlanRule(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyRollingDischargePlanRule(_ item: RollingDischargePlanRule) -> String {
        return pendingTransferSummaryBucket(item.projectedVolume())
    }
}
