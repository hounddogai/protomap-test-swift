import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetScoresForCheckpoint(_ items: [OrderSetScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveCappedCareProtocolCheckpointsFromScore(_ items: [OrderSetScore]) -> [CappedCareProtocolCheckpoint] {
        var out: [CappedCareProtocolCheckpoint] = []
        for item in items {
            let derived = newCappedCareProtocolCheckpoint(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceCappedCareProtocolCheckpointExtra(_ item: CappedCareProtocolCheckpoint) -> Double {
        return orderSetProposalWeight(7, active: true)
    }
}
