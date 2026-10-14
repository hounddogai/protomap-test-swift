import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackAccessionNoticesForSegment(_ items: [FallbackAccessionNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCourierSegmentsFromNotice(_ items: [FallbackAccessionNotice]) -> [CourierSegment] {
        var out: [CourierSegment] = []
        for item in items {
            let derived = newCourierSegment(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchCourierSegment(_ item: CourierSegment) -> Double {
        return accessionPolicyWeight(7, active: true)
    }
}
