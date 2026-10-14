import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceForecastsForClaim(_ items: [RemittanceForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveRemittanceClaimsFromForecast(_ items: [RemittanceForecast]) -> [RemittanceClaim] {
        var out: [RemittanceClaim] = []
        for item in items {
            let derived = newRemittanceClaim(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchRemittanceClaim(_ item: RemittanceClaim) -> String {
        return remittanceAdjustmentBucket(item.weightedLoad())
    }
}
