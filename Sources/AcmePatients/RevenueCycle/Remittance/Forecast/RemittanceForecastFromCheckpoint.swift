import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialCheckpointsForForecast(_ items: [DenialCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRemittanceForecastsFromCheckpoint(_ items: [DenialCheckpoint]) -> [RemittanceForecast] {
        var out: [RemittanceForecast] = []
        for item in items {
            let derived = newRemittanceForecast(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleRemittanceForecast(_ item: RemittanceForecast) -> String {
        return classifyDenialCheckpoint(item.effectiveVolume())
    }
}
