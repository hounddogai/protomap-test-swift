import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyTaskWindowsForWindow(_ items: [LegacyTaskWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedAlertWindowsFromWindow(_ items: [LegacyTaskWindow]) -> [CappedAlertWindow] {
        var out: [CappedAlertWindow] = []
        for item in items {
            let derived = newCappedAlertWindow(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignCappedAlertWindow(_ item: CappedAlertWindow) -> String {
        return normalizeTaskTemplateCode(item.code)
    }
}
