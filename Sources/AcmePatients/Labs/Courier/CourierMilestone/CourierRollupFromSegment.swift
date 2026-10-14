import AcmePlatform
import Foundation

extension Labs {
    static func summarizeDefaultReferenceRangeSegmentsForRollup(_ items: [DefaultReferenceRangeSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveCourierRollupsFromSegment(_ items: [DefaultReferenceRangeSegment]) -> [CourierRollup] {
        var out: [CourierRollup] = []
        for item in items {
            let derived = newCourierRollup(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitCourierRollup(_ item: CourierRollup) -> String {
        return normalizePendingReferenceRangeProfileCode(item.code)
    }
}
