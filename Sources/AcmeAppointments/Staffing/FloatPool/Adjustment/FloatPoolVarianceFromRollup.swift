import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCappedOvertimeRollupsForVariance(_ items: [CappedOvertimeRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveFloatPoolVariancesFromRollup(_ items: [CappedOvertimeRollup]) -> [FloatPoolVariance] {
        var out: [FloatPoolVariance] = []
        for item in items {
            let derived = newFloatPoolVariance(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyFloatPoolVariance(_ item: FloatPoolVariance) -> Double {
        return overtimeDigestWeight(6, active: true)
    }
}
