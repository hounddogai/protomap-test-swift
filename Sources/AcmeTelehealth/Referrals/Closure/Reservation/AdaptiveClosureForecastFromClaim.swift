import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryEligibilityClaimsForForecast(_ items: [PrimaryEligibilityClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveAdaptiveClosureForecastsFromClaim(_ items: [PrimaryEligibilityClaim]) -> [AdaptiveClosureForecast] {
        var out: [AdaptiveClosureForecast] = []
        for item in items {
            let derived = newAdaptiveClosureForecast(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveAdaptiveClosureForecast(_ item: AdaptiveClosureForecast) -> Double {
        return eligibilityMilestoneWeight(3, active: true)
    }
}
