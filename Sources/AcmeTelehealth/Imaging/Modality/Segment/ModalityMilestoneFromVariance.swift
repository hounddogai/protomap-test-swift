import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityVariancesForMilestone(_ items: [ModalityVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveModalityMilestonesFromVariance(_ items: [ModalityVariance]) -> [ModalityMilestone] {
        var out: [ModalityMilestone] = []
        for item in items {
            let derived = newModalityMilestone(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileModalityMilestone(_ item: ModalityMilestone) -> String {
        return classifyModalityRequest(item.weightedValue())
    }
}
