import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityRequestsForWindow(_ items: [ModalityRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func derivePriorityWindowsFromRequest(_ items: [ModalityRequest]) -> [PriorityWindow] {
        var out: [PriorityWindow] = []
        for item in items {
            let derived = newPriorityWindow(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPriorityWindow(_ item: PriorityWindow) -> String {
        return classifyModalityRequest(item.measuredValue())
    }
}
