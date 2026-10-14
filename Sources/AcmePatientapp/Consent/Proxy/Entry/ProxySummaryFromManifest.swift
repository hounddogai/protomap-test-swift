import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessManifestsForSummary(_ items: [WitnessManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveProxySummariesFromManifest(_ items: [WitnessManifest]) -> [ProxySummary] {
        var out: [ProxySummary] = []
        for item in items {
            let derived = newProxySummary(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveProxySummary(_ item: ProxySummary) -> String {
        return witnessForecastBucket(item.netExposure())
    }
}
