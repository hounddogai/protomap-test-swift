import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyGroupsForPreference(_ items: [StudyGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveCappedCareProtocolPreferencesFromGroup(_ items: [StudyGroup]) -> [CappedCareProtocolPreference] {
        var out: [CappedCareProtocolPreference] = []
        for item in items {
            let derived = newCappedCareProtocolPreference(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreCappedCareProtocolPreference(_ item: CappedCareProtocolPreference) -> String {
        return normalizeWeightedStudyForecastCode(item.code)
    }
}
