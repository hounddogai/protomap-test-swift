import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftQuotasForCheckpoint(_ items: [ShiftQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackOvertimeCheckpointsFromQuota(_ items: [ShiftQuota]) -> [FallbackOvertimeCheckpoint] {
        var out: [FallbackOvertimeCheckpoint] = []
        for item in items {
            let derived = newFallbackOvertimeCheckpoint(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectFallbackOvertimeCheckpoint(_ item: FallbackOvertimeCheckpoint) -> String {
        return classifyShiftBaseline(item.measuredValue())
    }
}
