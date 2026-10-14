import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGlobalProgramBundlesForPreference(_ items: [GlobalProgramBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveSeasonalRiskScorePreferencesFromBundle(_ items: [GlobalProgramBundle]) -> [SeasonalRiskScorePreference] {
        var out: [SeasonalRiskScorePreference] = []
        for item in items {
            let derived = newSeasonalRiskScorePreference(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectSeasonalRiskScorePreference(_ item: SeasonalRiskScorePreference) -> String {
        return globalProgramBundleBucket(item.projectedTotal())
    }
}
