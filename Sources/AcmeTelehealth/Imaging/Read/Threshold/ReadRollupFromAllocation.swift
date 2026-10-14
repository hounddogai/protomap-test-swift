import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityAllocationsForRollup(_ items: [PriorityAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveReadRollupsFromAllocation(_ items: [PriorityAllocation]) -> [ReadRollup] {
        var out: [ReadRollup] = []
        for item in items {
            let derived = newReadRollup(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeReadRollup(_ item: ReadRollup) -> String {
        return normalizePriorityAllocationCode(item.code)
    }
}
