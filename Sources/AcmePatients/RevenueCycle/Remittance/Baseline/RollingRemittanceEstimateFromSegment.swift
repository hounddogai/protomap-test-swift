import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRollingChargeSegmentsForEstimate(_ items: [RollingChargeSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveRollingRemittanceEstimatesFromSegment(_ items: [RollingChargeSegment]) -> [RollingRemittanceEstimate] {
        var out: [RollingRemittanceEstimate] = []
        for item in items {
            let derived = newRollingRemittanceEstimate(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRollingRemittanceEstimate(_ item: RollingRemittanceEstimate) -> String {
        return classifyRollingChargeSegment(item.weightedVolume())
    }
}
