import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeTieredStatementAdjustmentsForTemplate(_ items: [TieredStatementAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveWeightedClaimTemplatesFromAdjustment(_ items: [TieredStatementAdjustment]) -> [WeightedClaimTemplate] {
        var out: [WeightedClaimTemplate] = []
        for item in items {
            let derived = newWeightedClaimTemplate(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeWeightedClaimTemplate(_ item: WeightedClaimTemplate) -> String {
        return classifyStatementDraft(item.projectedVolume())
    }
}
