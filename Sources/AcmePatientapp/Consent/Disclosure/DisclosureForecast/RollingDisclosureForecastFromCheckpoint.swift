import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormCheckpointsForForecast(_ items: [ConsentFormCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveRollingDisclosureForecastsFromCheckpoint(_ items: [ConsentFormCheckpoint]) -> [RollingDisclosureForecast] {
        var out: [RollingDisclosureForecast] = []
        for item in items {
            let derived = newRollingDisclosureForecast(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRollingDisclosureForecast(_ item: RollingDisclosureForecast) -> String {
        return normalizeConsentFormCheckpointCode(item.code)
    }
}
