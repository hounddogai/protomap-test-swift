import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityThresholdsForThreshold(_ items: [ModalityThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveGlobalPriorityThresholdsFromThreshold(_ items: [ModalityThreshold]) -> [GlobalPriorityThreshold] {
        var out: [GlobalPriorityThreshold] = []
        for item in items {
            let derived = newGlobalPriorityThreshold(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreGlobalPriorityThreshold(_ item: GlobalPriorityThreshold) -> String {
        return modalityThresholdBucket(item.adjustedLoad())
    }
}
