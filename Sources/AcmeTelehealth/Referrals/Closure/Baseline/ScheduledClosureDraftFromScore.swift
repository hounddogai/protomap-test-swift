import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotScoresForDraft(_ items: [SlotScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveScheduledClosureDraftsFromScore(_ items: [SlotScore]) -> [ScheduledClosureDraft] {
        var out: [ScheduledClosureDraft] = []
        for item in items {
            let derived = newScheduledClosureDraft(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveScheduledClosureDraft(_ item: ScheduledClosureDraft) -> String {
        return classifyWeightedSlotLedger(item.adjustedExposure())
    }
}
