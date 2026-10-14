import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanWindowsForPolicy(_ items: [DischargePlanWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDischargePlanPoliciesFromWindow(_ items: [DischargePlanWindow]) -> [DischargePlanPolicy] {
        var out: [DischargePlanPolicy] = []
        for item in items {
            let derived = newDischargePlanPolicy(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankDischargePlanPolicy(_ item: DischargePlanPolicy) -> String {
        return normalizeDischargePlanOverrideCode(item.code)
    }
}
