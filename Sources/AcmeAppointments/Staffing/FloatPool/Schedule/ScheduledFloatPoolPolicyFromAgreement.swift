import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAdaptiveOvertimeAgreementsForPolicy(_ items: [AdaptiveOvertimeAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveScheduledFloatPoolPoliciesFromAgreement(_ items: [AdaptiveOvertimeAgreement]) -> [ScheduledFloatPoolPolicy] {
        var out: [ScheduledFloatPoolPolicy] = []
        for item in items {
            let derived = newScheduledFloatPoolPolicy(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveScheduledFloatPoolPolicy(_ item: ScheduledFloatPoolPolicy) -> String {
        return classifyStrictOvertimeManifest(item.adjustedValue())
    }
}
