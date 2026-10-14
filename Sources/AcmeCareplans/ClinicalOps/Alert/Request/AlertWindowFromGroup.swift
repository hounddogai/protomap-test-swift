import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskGroupsForWindow(_ items: [TaskGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveAlertWindowsFromGroup(_ items: [TaskGroup]) -> [AlertWindow] {
        var out: [AlertWindow] = []
        for item in items {
            let derived = newAlertWindow(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitAlertWindow(_ item: AlertWindow) -> String {
        return normalizeTaskExceptionCode(item.code)
    }
}
