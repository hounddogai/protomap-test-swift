import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeScheduledFollowUpDraftsForOverride(_ items: [ScheduledFollowUpDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveEligibilityOverridesFromDraft(_ items: [ScheduledFollowUpDraft]) -> [EligibilityOverride] {
        var out: [EligibilityOverride] = []
        for item in items {
            let derived = newEligibilityOverride(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyEligibilityOverrideExtra(_ item: EligibilityOverride) -> String {
        return normalizeScheduledFollowUpDraftCode(item.code)
    }
}
