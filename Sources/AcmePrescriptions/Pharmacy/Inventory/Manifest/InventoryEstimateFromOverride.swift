import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyOverridesForEstimate(_ items: [FormularyOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveInventoryEstimatesFromOverride(_ items: [FormularyOverride]) -> [InventoryEstimate] {
        var out: [InventoryEstimate] = []
        for item in items {
            let derived = newInventoryEstimate(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectInventoryEstimate(_ item: InventoryEstimate) -> Double {
        return fallbackFormularyDigestWeight(8, active: true)
    }
}
