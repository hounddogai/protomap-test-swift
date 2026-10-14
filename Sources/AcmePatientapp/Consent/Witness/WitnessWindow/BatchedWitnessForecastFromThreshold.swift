import AcmePlatform
import Foundation

extension Consent {
    static func summarizeManualWitnessThresholdsForForecast(_ items: [ManualWitnessThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveBatchedWitnessForecastsFromThreshold(_ items: [ManualWitnessThreshold]) -> [BatchedWitnessForecast] {
        var out: [BatchedWitnessForecast] = []
        for item in items {
            let derived = newBatchedWitnessForecast(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileBatchedWitnessForecast(_ item: BatchedWitnessForecast) -> String {
        return normalizeDefaultWitnessBaselineCode(item.code)
    }
}
