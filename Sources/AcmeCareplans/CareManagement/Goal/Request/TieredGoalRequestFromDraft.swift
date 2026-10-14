import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeSeasonalGoalDraftsForRequest(_ items: [SeasonalGoalDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveTieredGoalRequestsFromDraft(_ items: [SeasonalGoalDraft]) -> [TieredGoalRequest] {
        var out: [TieredGoalRequest] = []
        for item in items {
            let derived = newTieredGoalRequest(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateTieredGoalRequest(_ item: TieredGoalRequest) -> String {
        return normalizeSeasonalGoalDraftCode(item.code)
    }
}
