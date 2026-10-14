import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeNetworkClaimsForBaseline(_ items: [NetworkClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveEligibilityBaselinesFromClaim(_ items: [NetworkClaim]) -> [EligibilityBaseline] {
        var out: [EligibilityBaseline] = []
        for item in items {
            let derived = newEligibilityBaseline(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeEligibilityBaseline(_ item: EligibilityBaseline) -> String {
        return networkLedgerBucket(item.weightedTotal())
    }
}
