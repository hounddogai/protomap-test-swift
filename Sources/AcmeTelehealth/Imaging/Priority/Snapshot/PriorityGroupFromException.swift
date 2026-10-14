import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadExceptionsForGroup(_ items: [ReadException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func derivePriorityGroupsFromException(_ items: [ReadException]) -> [PriorityGroup] {
        var out: [PriorityGroup] = []
        for item in items {
            let derived = newPriorityGroup(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computePriorityGroup(_ item: PriorityGroup) -> String {
        return normalizeReadExceptionCode(item.code)
    }
}
