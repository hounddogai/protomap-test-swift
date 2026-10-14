import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGlobalCareGapAssignmentsForProposal(_ items: [GlobalCareGapAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveOutreachProposalsFromAssignment(_ items: [GlobalCareGapAssignment]) -> [OutreachProposal] {
        var out: [OutreachProposal] = []
        for item in items {
            let derived = newOutreachProposal(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyOutreachProposal(_ item: OutreachProposal) -> String {
        return weightedCareGapWindowBucket(item.weightedLoad())
    }
}
