import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRollingRoundingSlotsForVariance(_ items: [RollingRoundingSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveHandoffVariancesFromSlot(_ items: [RollingRoundingSlot]) -> [HandoffVariance] {
        var out: [HandoffVariance] = []
        for item in items {
            let derived = newHandoffVariance(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeHandoffVariance(_ item: HandoffVariance) -> String {
        return roundingScheduleBucket(item.netValue())
    }
}
