import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingClaimsForNotice(_ items: [RoundingClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveRollingAlertNoticesFromClaim(_ items: [RoundingClaim]) -> [RollingAlertNotice] {
        var out: [RollingAlertNotice] = []
        for item in items {
            let derived = newRollingAlertNotice(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyRollingAlertNotice(_ item: RollingAlertNotice) -> String {
        return classifyRoundingReview(item.effectiveExposure())
    }
}
