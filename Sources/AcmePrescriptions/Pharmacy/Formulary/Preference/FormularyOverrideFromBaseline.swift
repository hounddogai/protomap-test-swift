import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseBaselinesForOverride(_ items: [DispenseBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveFormularyOverridesFromBaseline(_ items: [DispenseBaseline]) -> [FormularyOverride] {
        var out: [FormularyOverride] = []
        for item in items {
            let derived = newFormularyOverride(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeFormularyOverride(_ item: FormularyOverride) -> String {
        return normalizeDispenseBaselineCode(item.code)
    }
}
