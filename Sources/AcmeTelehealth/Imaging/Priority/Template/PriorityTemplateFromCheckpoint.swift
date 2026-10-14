import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityCheckpointsForTemplate(_ items: [PriorityCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func derivePriorityTemplatesFromCheckpoint(_ items: [PriorityCheckpoint]) -> [PriorityTemplate] {
        var out: [PriorityTemplate] = []
        for item in items {
            let derived = newPriorityTemplate(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizePriorityTemplate(_ item: PriorityTemplate) -> String {
        return normalizePriorityCheckpointCode(item.code)
    }
}
