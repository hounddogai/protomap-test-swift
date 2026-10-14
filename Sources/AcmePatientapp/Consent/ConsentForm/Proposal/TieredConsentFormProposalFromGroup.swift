import AcmePlatform
import Foundation

extension Consent {
    static func summarizeSeasonalWitnessGroupsForProposal(_ items: [SeasonalWitnessGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveTieredConsentFormProposalsFromGroup(_ items: [SeasonalWitnessGroup]) -> [TieredConsentFormProposal] {
        var out: [TieredConsentFormProposal] = []
        for item in items {
            let derived = newTieredConsentFormProposal(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyTieredConsentFormProposal(_ item: TieredConsentFormProposal) -> String {
        return classifySeasonalWitnessGroup(item.netExposure())
    }
}
