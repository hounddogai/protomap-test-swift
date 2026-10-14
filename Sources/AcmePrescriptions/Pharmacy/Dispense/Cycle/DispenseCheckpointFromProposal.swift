import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionProposalsForCheckpoint(_ items: [SubstitutionProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveDispenseCheckpointsFromProposal(_ items: [SubstitutionProposal]) -> [DispenseCheckpoint] {
        var out: [DispenseCheckpoint] = []
        for item in items {
            let derived = newDispenseCheckpoint(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveDispenseCheckpoint(_ item: DispenseCheckpoint) -> Double {
        return substitutionProposalWeight(6, active: true)
    }
}
