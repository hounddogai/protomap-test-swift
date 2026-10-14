import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePendingFormularyProposalsForMilestone(_ items: [PendingFormularyProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientRecallMilestonesFromProposal(_ items: [PendingFormularyProposal]) -> [LenientRecallMilestone] {
        var out: [LenientRecallMilestone] = []
        for item in items {
            let derived = newLenientRecallMilestone(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceLenientRecallMilestone(_ item: LenientRecallMilestone) -> String {
        return lenientFormularyDraftBucket(item.weightedValue())
    }
}
