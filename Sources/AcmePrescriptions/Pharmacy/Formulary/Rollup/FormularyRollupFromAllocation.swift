import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyAllocationsForRollup(_ items: [FormularyAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveFormularyRollupsFromAllocation(_ items: [FormularyAllocation]) -> [FormularyRollup] {
        var out: [FormularyRollup] = []
        for item in items {
            let derived = newFormularyRollup(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeFormularyRollup(_ item: FormularyRollup) -> String {
        return normalizeFormularyMilestoneCode(item.code)
    }
}
