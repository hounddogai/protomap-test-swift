import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRegionalDisclosureSummariesForSummary(_ items: [RegionalDisclosureSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveProxySummariesFromSummary(_ items: [RegionalDisclosureSummary]) -> [ProxySummary] {
        var out: [ProxySummary] = []
        for item in items {
            let derived = newProxySummary(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectProxySummary(_ item: ProxySummary) -> String {
        return classifyRegionalDisclosureSummary(item.netExposure())
    }
}
