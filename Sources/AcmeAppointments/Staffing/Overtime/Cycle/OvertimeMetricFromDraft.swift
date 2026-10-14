import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftDraftsForMetric(_ items: [ShiftDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveOvertimeMetricsFromDraft(_ items: [ShiftDraft]) -> [OvertimeMetric] {
        var out: [OvertimeMetric] = []
        for item in items {
            let derived = newOvertimeMetric(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeOvertimeMetric(_ item: OvertimeMetric) -> String {
        return normalizeShiftSnapshotCode(item.code)
    }
}
