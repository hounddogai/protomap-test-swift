import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCappedCareProtocolScoresForPolicy(_ items: [CappedCareProtocolScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveLegacyPriorityPoliciesFromScore(_ items: [CappedCareProtocolScore]) -> [LegacyPriorityPolicy] {
        var out: [LegacyPriorityPolicy] = []
        for item in items {
            let derived = newLegacyPriorityPolicy(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveLegacyPriorityPolicy(_ item: LegacyPriorityPolicy) -> String {
        return classifyRollingCareProtocolManifest(item.adjustedExposure())
    }
}
