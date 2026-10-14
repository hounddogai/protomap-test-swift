import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeManualAlertRecordsForProposal(_ items: [ManualAlertRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveStrictRoundingProposalsFromRecord(_ items: [ManualAlertRecord]) -> [StrictRoundingProposal] {
        var out: [StrictRoundingProposal] = []
        for item in items {
            let derived = newStrictRoundingProposal(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyStrictRoundingProposalExtra(_ item: StrictRoundingProposal) -> String {
        return normalizeScheduledAlertRollupCode(item.code)
    }
}
