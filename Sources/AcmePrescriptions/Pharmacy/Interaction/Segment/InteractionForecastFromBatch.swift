import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeManualSubstitutionBatchesForForecast(_ items: [ManualSubstitutionBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveInteractionForecastsFromBatch(_ items: [ManualSubstitutionBatch]) -> [InteractionForecast] {
        var out: [InteractionForecast] = []
        for item in items {
            let derived = newInteractionForecast(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectInteractionForecast(_ item: InteractionForecast) -> Double {
        return substitutionRecordWeight(1, active: true)
    }
}
