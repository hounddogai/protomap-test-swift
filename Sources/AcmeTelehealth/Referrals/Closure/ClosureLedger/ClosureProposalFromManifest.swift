import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeWeightedFollowUpManifestsForProposal(_ items: [WeightedFollowUpManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveClosureProposalsFromManifest(_ items: [WeightedFollowUpManifest]) -> [ClosureProposal] {
        var out: [ClosureProposal] = []
        for item in items {
            let derived = newClosureProposal(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeClosureProposal(_ item: ClosureProposal) -> Double {
        return tieredFollowUpReservationWeight(7, active: true)
    }
}
