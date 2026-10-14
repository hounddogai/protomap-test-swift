import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStrictReadDraftsForPlan(_ items: [StrictReadDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveStrictWorklistPlansFromDraft(_ items: [StrictReadDraft]) -> [StrictWorklistPlan] {
        var out: [StrictWorklistPlan] = []
        for item in items {
            let derived = newStrictWorklistPlan(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreStrictWorklistPlan(_ item: StrictWorklistPlan) -> String {
        return normalizeTieredReadQuotaCode(item.code)
    }
}
