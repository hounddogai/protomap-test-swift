import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityWindowsForRequest(_ items: [PriorityWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveReadRequestsFromWindow(_ items: [PriorityWindow]) -> [ReadRequest] {
        var out: [ReadRequest] = []
        for item in items {
            let derived = newReadRequest(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleReadRequest(_ item: ReadRequest) -> String {
        return normalizePriorityWindowCode(item.code)
    }
}
