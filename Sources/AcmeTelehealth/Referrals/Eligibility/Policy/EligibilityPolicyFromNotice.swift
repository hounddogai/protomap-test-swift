import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryClosureNoticesForPolicy(_ items: [PrimaryClosureNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveEligibilityPoliciesFromNotice(_ items: [PrimaryClosureNotice]) -> [EligibilityPolicy] {
        var out: [EligibilityPolicy] = []
        for item in items {
            let derived = newEligibilityPolicy(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeEligibilityPolicy(_ item: EligibilityPolicy) -> String {
        return weightedClosureBaselineBucket(item.effectiveTotal())
    }
}
