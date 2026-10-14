import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessForecastsForSlot(_ items: [WitnessForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveWitnessSlotsFromForecast(_ items: [WitnessForecast]) -> [WitnessSlot] {
        var out: [WitnessSlot] = []
        for item in items {
            let derived = newWitnessSlot(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleWitnessSlot(_ item: WitnessSlot) -> Double {
        return witnessForecastWeight(3, active: true)
    }
}
