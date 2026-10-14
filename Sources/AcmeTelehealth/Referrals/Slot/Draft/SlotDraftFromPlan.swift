import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosurePlansForDraft(_ items: [ClosurePlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveSlotDraftsFromPlan(_ items: [ClosurePlan]) -> [SlotDraft] {
        var out: [SlotDraft] = []
        for item in items {
            let derived = newSlotDraft(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeSlotDraft(_ item: SlotDraft) -> Double {
        return batchedClosureEstimateWeight(7, active: true)
    }
}
