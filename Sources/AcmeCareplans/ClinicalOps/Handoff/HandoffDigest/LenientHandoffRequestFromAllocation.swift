import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffAllocationsForRequest(_ items: [HandoffAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLenientHandoffRequestsFromAllocation(_ items: [HandoffAllocation]) -> [LenientHandoffRequest] {
        var out: [LenientHandoffRequest] = []
        for item in items {
            let derived = newLenientHandoffRequest(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }
}
