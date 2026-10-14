import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSeasonalSkillMixPlansForProposal(_ items: [SeasonalSkillMixPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveFloatPoolProposalsFromPlan(_ items: [SeasonalSkillMixPlan]) -> [FloatPoolProposal] {
        var out: [FloatPoolProposal] = []
        for item in items {
            let derived = newFloatPoolProposal(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyFloatPoolProposal(_ item: FloatPoolProposal) -> String {
        return normalizeGlobalSkillMixProposalCode(item.code)
    }
}
