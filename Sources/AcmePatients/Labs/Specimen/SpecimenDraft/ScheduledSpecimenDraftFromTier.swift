import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionTiersForDraft(_ items: [AccessionTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledSpecimenDraftsFromTier(_ items: [AccessionTier]) -> [ScheduledSpecimenDraft] {
        var out: [ScheduledSpecimenDraft] = []
        for item in items {
            let derived = newScheduledSpecimenDraft(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleScheduledSpecimenDraft(_ item: ScheduledSpecimenDraft) -> String {
        return normalizeAccessionPlanCode(item.code)
    }
}
