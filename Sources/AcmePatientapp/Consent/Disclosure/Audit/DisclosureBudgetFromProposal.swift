import AcmePlatform
import Foundation

extension Consent {
    static func summarizeTieredConsentFormProposalsForBudget(_ items: [TieredConsentFormProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveDisclosureBudgetsFromProposal(_ items: [TieredConsentFormProposal]) -> [DisclosureBudget] {
        var out: [DisclosureBudget] = []
        for item in items {
            let derived = newDisclosureBudget(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreDisclosureBudget(_ item: DisclosureBudget) -> String {
        return normalizeRollingConsentFormAllocationCode(item.code)
    }
}
