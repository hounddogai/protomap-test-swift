import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeFallbackCareProtocolWindowsForAssignment(_ items: [FallbackCareProtocolWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func derivePriorityAssignmentsFromWindow(_ items: [FallbackCareProtocolWindow]) -> [PriorityAssignment] {
        var out: [PriorityAssignment] = []
        for item in items {
            let derived = newPriorityAssignment(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPriorityAssignment(_ item: PriorityAssignment) -> Double {
        return fallbackCareProtocolWindowWeight(9, active: true)
    }
}
