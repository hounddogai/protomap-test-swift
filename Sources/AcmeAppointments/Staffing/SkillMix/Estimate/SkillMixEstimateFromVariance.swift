import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialVariancesForEstimate(_ items: [CredentialVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveSkillMixEstimatesFromVariance(_ items: [CredentialVariance]) -> [SkillMixEstimate] {
        var out: [SkillMixEstimate] = []
        for item in items {
            let derived = newSkillMixEstimate(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifySkillMixEstimate(_ item: SkillMixEstimate) -> Double {
        return credentialBundleWeight(3, active: true)
    }
}
