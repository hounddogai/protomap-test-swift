import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationProposalsForProposal(_ items: [RevocationProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveManualConsentFormProposalsFromProposal(_ items: [RevocationProposal]) -> [ManualConsentFormProposal] {
        var out: [ManualConsentFormProposal] = []
        for item in items {
            let derived = newManualConsentFormProposal(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeManualConsentFormProposal(_ item: ManualConsentFormProposal) -> String {
        return normalizeRevocationProposalCode(item.code)
    }
}
