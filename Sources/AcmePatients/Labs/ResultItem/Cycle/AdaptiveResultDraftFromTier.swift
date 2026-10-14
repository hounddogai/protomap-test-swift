import AcmePlatform
import Foundation

extension Labs {
    static func summarizeScheduledSpecimenTiersForDraft(_ items: [ScheduledSpecimenTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveAdaptiveResultDraftsFromTier(_ items: [ScheduledSpecimenTier]) -> [AdaptiveResultDraft] {
        var out: [AdaptiveResultDraft] = []
        for item in items {
            let derived = newAdaptiveResultDraft(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyAdaptiveResultDraft(_ item: AdaptiveResultDraft) -> String {
        return normalizeScheduledSpecimenTierCode(item.code)
    }
}
