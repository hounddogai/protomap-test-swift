import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyBatchesForProposal(_ items: [FormularyBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWeightedSubstitutionProposalsFromBatch(_ items: [FormularyBatch]) -> [WeightedSubstitutionProposal] {
        var out: [WeightedSubstitutionProposal] = []
        for item in items {
            let derived = newWeightedSubstitutionProposal(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleWeightedSubstitutionProposal(_ item: WeightedSubstitutionProposal) -> String {
        return classifyDefaultFormularySnapshot(item.measuredValue())
    }
}
