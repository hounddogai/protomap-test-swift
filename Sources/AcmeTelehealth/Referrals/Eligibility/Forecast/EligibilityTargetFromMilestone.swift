import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityMilestonesForTarget(_ items: [EligibilityMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveEligibilityTargetsFromMilestone(_ items: [EligibilityMilestone]) -> [EligibilityTarget] {
        var out: [EligibilityTarget] = []
        for item in items {
            let derived = newEligibilityTarget(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeEligibilityTarget(_ item: EligibilityTarget) -> String {
        return normalizePrimaryEligibilityClaimCode(item.code)
    }
}
