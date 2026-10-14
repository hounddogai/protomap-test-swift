import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeWeightedAcuityPlanEstimatesForGroup(_ items: [WeightedAcuityPlanEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveCredentialGroupsFromEstimate(_ items: [WeightedAcuityPlanEstimate]) -> [CredentialGroup] {
        var out: [CredentialGroup] = []
        for item in items {
            let derived = newCredentialGroup(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreCredentialGroup(_ item: CredentialGroup) -> String {
        return classifyWeightedAcuityPlanEstimate(item.netTotal())
    }
}
