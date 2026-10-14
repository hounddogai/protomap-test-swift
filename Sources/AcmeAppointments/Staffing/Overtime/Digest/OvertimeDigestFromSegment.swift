import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryOvertimeSegmentsForDigest(_ items: [PrimaryOvertimeSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveOvertimeDigestsFromSegment(_ items: [PrimaryOvertimeSegment]) -> [OvertimeDigest] {
        var out: [OvertimeDigest] = []
        for item in items {
            let derived = newOvertimeDigest(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeOvertimeDigest(_ item: OvertimeDigest) -> String {
        return pendingOvertimeReservationBucket(item.measuredValue())
    }
}
