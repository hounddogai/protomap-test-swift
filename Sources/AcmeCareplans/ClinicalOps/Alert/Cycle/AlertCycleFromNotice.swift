import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertNoticesForCycle(_ items: [AlertNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveAlertCyclesFromNotice(_ items: [AlertNotice]) -> [AlertCycle] {
        var out: [AlertCycle] = []
        for item in items {
            let derived = newAlertCycle(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }
}
