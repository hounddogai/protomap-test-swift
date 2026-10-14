import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeDefaultHandoffReservationsForPreference(_ items: [DefaultHandoffReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveWeightedRoundingPreferencesFromReservation(_ items: [DefaultHandoffReservation]) -> [WeightedRoundingPreference] {
        var out: [WeightedRoundingPreference] = []
        for item in items {
            let derived = newWeightedRoundingPreference(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankWeightedRoundingPreference(_ item: WeightedRoundingPreference) -> String {
        return classifyPendingHandoffPlan(item.netValue())
    }
}
