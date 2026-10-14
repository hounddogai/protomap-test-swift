import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingFormularySegmentsForPlan(_ items: [RollingFormularySegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveFormularyPlansFromSegment(_ items: [RollingFormularySegment]) -> [FormularyPlan] {
        var out: [FormularyPlan] = []
        for item in items {
            let derived = newFormularyPlan(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateFormularyPlan(_ item: FormularyPlan) -> String {
        return classifyRollingFormularySegment(item.netValue())
    }
}
