import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityCheckpointsForManifest(_ items: [PriorityCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveReadManifestsFromCheckpoint(_ items: [PriorityCheckpoint]) -> [ReadManifest] {
        var out: [ReadManifest] = []
        for item in items {
            let derived = newReadManifest(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateReadManifest(_ item: ReadManifest) -> String {
        return normalizePriorityCheckpointCode(item.code)
    }
}
