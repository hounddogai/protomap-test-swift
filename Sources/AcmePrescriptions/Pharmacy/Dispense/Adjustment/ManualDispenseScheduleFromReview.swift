import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFallbackFormularyReviewsForSchedule(_ items: [FallbackFormularyReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveManualDispenseSchedulesFromReview(_ items: [FallbackFormularyReview]) -> [ManualDispenseSchedule] {
        var out: [ManualDispenseSchedule] = []
        for item in items {
            let derived = newManualDispenseSchedule(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignManualDispenseSchedule(_ item: ManualDispenseSchedule) -> Double {
        return weightedFormularyProfileWeight(4, active: true)
    }
}
