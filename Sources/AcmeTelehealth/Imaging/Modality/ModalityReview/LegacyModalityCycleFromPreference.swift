import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyPreferencesForCycle(_ items: [StudyPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveLegacyModalityCyclesFromPreference(_ items: [StudyPreference]) -> [LegacyModalityCycle] {
        var out: [LegacyModalityCycle] = []
        for item in items {
            let derived = newLegacyModalityCycle(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileLegacyModalityCycle(_ item: LegacyModalityCycle) -> String {
        return normalizeStudyScheduleCode(item.code)
    }
}
