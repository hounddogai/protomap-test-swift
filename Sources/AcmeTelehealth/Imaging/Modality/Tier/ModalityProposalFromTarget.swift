import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolTargetsForProposal(_ items: [CareProtocolTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveModalityProposalsFromTarget(_ items: [CareProtocolTarget]) -> [ModalityProposal] {
        var out: [ModalityProposal] = []
        for item in items {
            let derived = newModalityProposal(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignModalityProposal(_ item: ModalityProposal) -> String {
        return classifyLenientCareProtocolClaim(item.measuredValue())
    }
}
