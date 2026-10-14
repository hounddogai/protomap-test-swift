import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWeightedReadProposalsForBaseline(_ items: [WeightedReadProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveStrictReadBaselinesFromProposal(_ items: [WeightedReadProposal]) -> [StrictReadBaseline] {
        var out: [StrictReadBaseline] = []
        for item in items {
            let derived = newStrictReadBaseline(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeStrictReadBaseline(_ item: StrictReadBaseline) -> String {
        return normalizeWeightedReadProposalCode(item.code)
    }
}
