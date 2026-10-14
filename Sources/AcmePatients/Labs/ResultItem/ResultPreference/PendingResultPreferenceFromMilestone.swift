import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionMilestonesForPreference(_ items: [AccessionMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingResultPreferencesFromMilestone(_ items: [AccessionMilestone]) -> [PendingResultPreference] {
        var out: [PendingResultPreference] = []
        for item in items {
            let derived = newPendingResultPreference(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizePendingResultPreference(_ item: PendingResultPreference) -> String {
        return normalizeAccessionProfileCode(item.code)
    }
}
