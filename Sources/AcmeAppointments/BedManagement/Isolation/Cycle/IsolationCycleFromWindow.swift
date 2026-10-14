import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanWindowsForCycle(_ items: [DischargePlanWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveIsolationCyclesFromWindow(_ items: [DischargePlanWindow]) -> [IsolationCycle] {
        var out: [IsolationCycle] = []
        for item in items {
            let derived = newIsolationCycle(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeIsolationCycle(_ item: IsolationCycle) -> String {
        return normalizeDischargePlanAgreementCode(item.code)
    }
}
