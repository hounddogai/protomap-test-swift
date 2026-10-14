import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePendingEligibilityForecastsForLedger(_ items: [PendingEligibilityForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveReferralLedgersFromForecast(_ items: [PendingEligibilityForecast]) -> [ReferralLedger] {
        var out: [ReferralLedger] = []
        for item in items {
            let derived = newReferralLedger(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchReferralLedger(_ item: ReferralLedger) -> Double {
        return pendingEligibilityForecastWeight(1, active: true)
    }
}
