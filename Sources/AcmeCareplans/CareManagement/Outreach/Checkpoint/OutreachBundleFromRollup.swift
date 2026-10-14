import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentRollupsForBundle(_ items: [AssessmentRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveOutreachBundlesFromRollup(_ items: [AssessmentRollup]) -> [OutreachBundle] {
        var out: [OutreachBundle] = []
        for item in items {
            let derived = newOutreachBundle(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceOutreachBundle(_ item: OutreachBundle) -> String {
        return assessmentRollupBucket(item.effectiveExposure())
    }
}
