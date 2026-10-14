import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingInteractionSegmentsForPolicy(_ items: [RollingInteractionSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func derivePrimaryRecallPoliciesFromSegment(_ items: [RollingInteractionSegment]) -> [PrimaryRecallPolicy] {
        var out: [PrimaryRecallPolicy] = []
        for item in items {
            let derived = newPrimaryRecallPolicy(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchPrimaryRecallPolicy(_ item: PrimaryRecallPolicy) -> String {
        return legacyInteractionForecastBucket(item.measuredValue())
    }
}
