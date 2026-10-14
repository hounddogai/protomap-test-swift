import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRollingAccessionSegmentsForNotice(_ items: [RollingAccessionSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveCourierNoticesFromSegment(_ items: [RollingAccessionSegment]) -> [CourierNotice] {
        var out: [CourierNotice] = []
        for item in items {
            let derived = newCourierNotice(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateCourierNotice(_ item: CourierNotice) -> String {
        return classifyRollingAccessionSegment(item.measuredValue())
    }
}
