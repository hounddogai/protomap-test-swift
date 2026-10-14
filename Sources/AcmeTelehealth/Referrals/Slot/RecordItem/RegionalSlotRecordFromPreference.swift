import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpPreferencesForRecord(_ items: [FollowUpPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveRegionalSlotRecordsFromPreference(_ items: [FollowUpPreference]) -> [RegionalSlotRecord] {
        var out: [RegionalSlotRecord] = []
        for item in items {
            let derived = newRegionalSlotRecord(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRegionalSlotRecord(_ item: RegionalSlotRecord) -> String {
        return normalizeTieredFollowUpProfileCode(item.code)
    }
}
