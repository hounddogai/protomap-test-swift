import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeStrictSubstitutionProposalsForBundle(_ items: [StrictSubstitutionProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveWeightedRecallBundlesFromProposal(_ items: [StrictSubstitutionProposal]) -> [WeightedRecallBundle] {
        var out: [WeightedRecallBundle] = []
        for item in items {
            let derived = newWeightedRecallBundle(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitWeightedRecallBundle(_ item: WeightedRecallBundle) -> Double {
        return substitutionEntryWeight(2, active: true)
    }
}
