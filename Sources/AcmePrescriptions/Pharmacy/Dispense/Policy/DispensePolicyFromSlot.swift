import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularySlotsForPolicy(_ items: [FormularySlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveDispensePoliciesFromSlot(_ items: [FormularySlot]) -> [DispensePolicy] {
        var out: [DispensePolicy] = []
        for item in items {
            let derived = newDispensePolicy(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateDispensePolicy(_ item: DispensePolicy) -> String {
        return normalizeFormularySegmentCode(item.code)
    }
}
