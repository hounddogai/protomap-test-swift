import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePendingReferralLedgersForForecast(_ items: [PendingReferralLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveCappedSlotForecastsFromLedger(_ items: [PendingReferralLedger]) -> [CappedSlotForecast] {
        var out: [CappedSlotForecast] = []
        for item in items {
            let derived = newCappedSlotForecast(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchCappedSlotForecast(_ item: CappedSlotForecast) -> String {
        return pendingReferralLedgerBucket(item.netExposure())
    }
}
