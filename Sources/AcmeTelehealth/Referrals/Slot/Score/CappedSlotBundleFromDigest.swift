import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeRegionalFollowUpDigestsForBundle(_ items: [RegionalFollowUpDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveCappedSlotBundlesFromDigest(_ items: [RegionalFollowUpDigest]) -> [CappedSlotBundle] {
        var out: [CappedSlotBundle] = []
        for item in items {
            let derived = newCappedSlotBundle(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreCappedSlotBundle(_ item: CappedSlotBundle) -> String {
        return classifyStrictFollowUpAudit(item.adjustedValue())
    }
}
