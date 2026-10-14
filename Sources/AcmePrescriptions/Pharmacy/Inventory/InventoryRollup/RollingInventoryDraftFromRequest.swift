import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionRequestsForDraft(_ items: [SubstitutionRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRollingInventoryDraftsFromRequest(_ items: [SubstitutionRequest]) -> [RollingInventoryDraft] {
        var out: [RollingInventoryDraft] = []
        for item in items {
            let derived = newRollingInventoryDraft(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeRollingInventoryDraft(_ item: RollingInventoryDraft) -> Double {
        return substitutionPlanWeight(9, active: true)
    }
}
