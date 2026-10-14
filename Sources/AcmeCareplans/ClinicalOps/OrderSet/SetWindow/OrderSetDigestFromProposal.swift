import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeDefaultTaskProposalsForDigest(_ items: [DefaultTaskProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveOrderSetDigestsFromProposal(_ items: [DefaultTaskProposal]) -> [OrderSetDigest] {
        var out: [OrderSetDigest] = []
        for item in items {
            let derived = newOrderSetDigest(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreOrderSetDigest(_ item: OrderSetDigest) -> Double {
        return globalTaskLedgerWeight(2, active: true)
    }
}
