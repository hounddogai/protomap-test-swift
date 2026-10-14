import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionPoliciesForEstimate(_ items: [AccessionPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveRegionalSpecimenEstimatesFromPolicy(_ items: [AccessionPolicy]) -> [RegionalSpecimenEstimate] {
        var out: [RegionalSpecimenEstimate] = []
        for item in items {
            let derived = newRegionalSpecimenEstimate(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceRegionalSpecimenEstimate(_ item: RegionalSpecimenEstimate) -> String {
        return normalizeAccessionPolicyCode(item.code)
    }
}
