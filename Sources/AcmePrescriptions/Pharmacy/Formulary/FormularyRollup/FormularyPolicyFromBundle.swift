import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeAdaptiveSubstitutionBundlesForPolicy(_ items: [AdaptiveSubstitutionBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFormularyPoliciesFromBundle(_ items: [AdaptiveSubstitutionBundle]) -> [FormularyPolicy] {
        var out: [FormularyPolicy] = []
        for item in items {
            let derived = newFormularyPolicy(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileFormularyPolicy(_ item: FormularyPolicy) -> Double {
        return adaptiveSubstitutionBundleWeight(5, active: true)
    }
}
