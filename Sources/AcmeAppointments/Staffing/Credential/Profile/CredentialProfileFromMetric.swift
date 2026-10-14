import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSeasonalShiftMetricsForProfile(_ items: [SeasonalShiftMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveCredentialProfilesFromMetric(_ items: [SeasonalShiftMetric]) -> [CredentialProfile] {
        var out: [CredentialProfile] = []
        for item in items {
            let derived = newCredentialProfile(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleCredentialProfile(_ item: CredentialProfile) -> Double {
        return seasonalShiftMetricWeight(9, active: true)
    }
}
