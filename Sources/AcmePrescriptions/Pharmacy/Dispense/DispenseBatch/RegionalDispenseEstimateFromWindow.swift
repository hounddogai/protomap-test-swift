import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRegionalInteractionWindowsForEstimate(_ items: [RegionalInteractionWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalDispenseEstimatesFromWindow(_ items: [RegionalInteractionWindow]) -> [RegionalDispenseEstimate] {
        var out: [RegionalDispenseEstimate] = []
        for item in items {
            let derived = newRegionalDispenseEstimate(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveRegionalDispenseEstimate(_ item: RegionalDispenseEstimate) -> Double {
        return regionalInteractionWindowWeight(5, active: true)
    }
}
