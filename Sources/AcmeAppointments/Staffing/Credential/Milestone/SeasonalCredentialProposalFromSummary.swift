import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLegacyAcuityPlanSummariesForProposal(_ items: [LegacyAcuityPlanSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalCredentialProposalsFromSummary(_ items: [LegacyAcuityPlanSummary]) -> [SeasonalCredentialProposal] {
        var out: [SeasonalCredentialProposal] = []
        for item in items {
            let derived = newSeasonalCredentialProposal(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileSeasonalCredentialProposal(_ item: SeasonalCredentialProposal) -> String {
        return classifyLegacyAcuityPlanSummary(item.projectedValue())
    }
}
