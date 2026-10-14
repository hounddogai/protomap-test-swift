import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeStrictShiftScoresForEstimate(_ items: [StrictShiftScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRollingFloatPoolEstimatesFromScore(_ items: [StrictShiftScore]) -> [RollingFloatPoolEstimate] {
        var out: [RollingFloatPoolEstimate] = []
        for item in items {
            let derived = newRollingFloatPoolEstimate(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankRollingFloatPoolEstimate(_ item: RollingFloatPoolEstimate) -> String {
        return strictShiftScoreBucket(item.netValue())
    }
}
