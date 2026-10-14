import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeManualClosureRollupsForProposal(_ items: [ManualClosureRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualReferralProposalsFromRollup(_ items: [ManualClosureRollup]) -> [ManualReferralProposal] {
        var out: [ManualReferralProposal] = []
        for item in items {
            let derived = newManualReferralProposal(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchManualReferralProposal(_ item: ManualReferralProposal) -> Double {
        return strictClosureReservationWeight(4, active: true)
    }
}
