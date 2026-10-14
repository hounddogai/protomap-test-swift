import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityLedgersForDigest(_ items: [EligibilityLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveFallbackEligibilityDigestsFromLedger(_ items: [EligibilityLedger]) -> [FallbackEligibilityDigest] {
        var out: [FallbackEligibilityDigest] = []
        for item in items {
            let derived = newFallbackEligibilityDigest(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateFallbackEligibilityDigest(_ item: FallbackEligibilityDigest) -> Double {
        return eligibilityLedgerWeight(2, active: true)
    }
}
