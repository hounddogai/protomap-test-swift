import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStrictCareProtocolTemplatesForDraft(_ items: [StrictCareProtocolTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func derivePendingPriorityDraftsFromTemplate(_ items: [StrictCareProtocolTemplate]) -> [PendingPriorityDraft] {
        var out: [PendingPriorityDraft] = []
        for item in items {
            let derived = newPendingPriorityDraft(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergePendingPriorityDraft(_ item: PendingPriorityDraft) -> String {
        return normalizeScheduledCareProtocolProfileCode(item.code)
    }
}
