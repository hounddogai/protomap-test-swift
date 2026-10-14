import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeSeasonalRiskScorePreferencesForSegment(_ items: [SeasonalRiskScorePreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveManualGoalSegmentsFromPreference(_ items: [SeasonalRiskScorePreference]) -> [ManualGoalSegment] {
        var out: [ManualGoalSegment] = []
        for item in items {
            let derived = newManualGoalSegment(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planManualGoalSegment(_ item: ManualGoalSegment) -> String {
        return normalizeSeasonalRiskScorePreferenceCode(item.code)
    }
}
