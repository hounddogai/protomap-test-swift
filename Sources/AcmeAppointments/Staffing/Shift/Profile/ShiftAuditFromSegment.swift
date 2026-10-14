import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeSegmentsForAudit(_ items: [OvertimeSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveShiftAuditsFromSegment(_ items: [OvertimeSegment]) -> [ShiftAudit] {
        var out: [ShiftAudit] = []
        for item in items {
            let derived = newShiftAudit(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planShiftAudit(_ item: ShiftAudit) -> String {
        return classifyOvertimeVariance(item.adjustedVolume())
    }
}
