import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRegionalOvertimeSegmentsForSummary(_ items: [RegionalOvertimeSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveOvertimeSummariesFromSegment(_ items: [RegionalOvertimeSegment]) -> [OvertimeSummary] {
        var out: [OvertimeSummary] = []
        for item in items {
            let derived = newOvertimeSummary(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreOvertimeSummary(_ item: OvertimeSummary) -> Double {
        return scheduledOvertimeProposalWeight(4, active: true)
    }
}
