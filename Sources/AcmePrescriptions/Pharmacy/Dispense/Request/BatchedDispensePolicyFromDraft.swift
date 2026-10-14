import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionDraftsForPolicy(_ items: [SubstitutionDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveBatchedDispensePoliciesFromDraft(_ items: [SubstitutionDraft]) -> [BatchedDispensePolicy] {
        var out: [BatchedDispensePolicy] = []
        for item in items {
            let derived = newBatchedDispensePolicy(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeBatchedDispensePolicy(_ item: BatchedDispensePolicy) -> Double {
        return substitutionDraftWeight(8, active: true)
    }
}
