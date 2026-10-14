import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFallbackSkillMixLedgersForProposal(_ items: [FallbackSkillMixLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveManualOvertimeProposalsFromLedger(_ items: [FallbackSkillMixLedger]) -> [ManualOvertimeProposal] {
        var out: [ManualOvertimeProposal] = []
        for item in items {
            let derived = newManualOvertimeProposal(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeManualOvertimeProposal(_ item: ManualOvertimeProposal) -> String {
        return fallbackSkillMixTargetBucket(item.weightedLoad())
    }
}
