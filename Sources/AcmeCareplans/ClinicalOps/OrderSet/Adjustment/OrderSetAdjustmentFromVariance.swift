import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffVariancesForAdjustment(_ items: [HandoffVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveOrderSetAdjustmentsFromVariance(_ items: [HandoffVariance]) -> [OrderSetAdjustment] {
        var out: [OrderSetAdjustment] = []
        for item in items {
            let derived = newOrderSetAdjustment(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyOrderSetAdjustment(_ item: OrderSetAdjustment) -> String {
        return normalizeSeasonalHandoffWindowCode(item.code)
    }
}
