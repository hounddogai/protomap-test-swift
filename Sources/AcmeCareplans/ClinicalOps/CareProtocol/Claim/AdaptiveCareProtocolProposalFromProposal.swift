import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertProposalsForProposal(_ items: [AlertProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveAdaptiveCareProtocolProposalsFromProposal(_ items: [AlertProposal]) -> [AdaptiveCareProtocolProposal] {
        var out: [AdaptiveCareProtocolProposal] = []
        for item in items {
            let derived = newAdaptiveCareProtocolProposal(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileAdaptiveCareProtocolProposal(_ item: AdaptiveCareProtocolProposal) -> String {
        return classifyAlertProposal(item.weightedExposure())
    }
}
