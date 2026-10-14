import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalHandoffBudgetsForRequest(_ items: [SeasonalHandoffBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveTieredRoundingRequestsFromBudget(_ items: [SeasonalHandoffBudget]) -> [TieredRoundingRequest] {
        var out: [TieredRoundingRequest] = []
        for item in items {
            let derived = newTieredRoundingRequest(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitTieredRoundingRequest(_ item: TieredRoundingRequest) -> Double {
        return seasonalHandoffBudgetWeight(1, active: true)
    }
}
