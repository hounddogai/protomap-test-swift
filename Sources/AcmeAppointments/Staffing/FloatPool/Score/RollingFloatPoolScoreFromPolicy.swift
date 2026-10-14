import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeScheduledFloatPoolPoliciesForScore(_ items: [ScheduledFloatPoolPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveRollingFloatPoolScoresFromPolicy(_ items: [ScheduledFloatPoolPolicy]) -> [RollingFloatPoolScore] {
        var out: [RollingFloatPoolScore] = []
        for item in items {
            let derived = newRollingFloatPoolScore(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyRollingFloatPoolScore(_ item: RollingFloatPoolScore) -> Double {
        return scheduledFloatPoolPolicyWeight(5, active: true)
    }
}
