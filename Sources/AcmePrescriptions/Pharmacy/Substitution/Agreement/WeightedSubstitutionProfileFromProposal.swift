import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeBatchedSubstitutionProposalsForProfile(_ items: [BatchedSubstitutionProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveWeightedSubstitutionProfilesFromProposal(_ items: [BatchedSubstitutionProposal]) -> [WeightedSubstitutionProfile] {
        var out: [WeightedSubstitutionProfile] = []
        for item in items {
            let derived = newWeightedSubstitutionProfile(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchWeightedSubstitutionProfile(_ item: WeightedSubstitutionProfile) -> String {
        return classifyPrimarySubstitutionAssignment(item.effectiveVolume())
    }
}
