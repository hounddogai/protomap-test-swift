import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryCyclesForDigest(_ items: [InventoryCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveAdaptiveInteractionDigestsFromCycle(_ items: [InventoryCycle]) -> [AdaptiveInteractionDigest] {
        var out: [AdaptiveInteractionDigest] = []
        for item in items {
            let derived = newAdaptiveInteractionDigest(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleAdaptiveInteractionDigest(_ item: AdaptiveInteractionDigest) -> String {
        return normalizeInventoryCycleCode(item.code)
    }
}
