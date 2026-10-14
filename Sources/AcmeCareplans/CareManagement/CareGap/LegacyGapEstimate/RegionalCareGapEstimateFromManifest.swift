import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingProgramManifestsForEstimate(_ items: [PendingProgramManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveRegionalCareGapEstimatesFromManifest(_ items: [PendingProgramManifest]) -> [RegionalCareGapEstimate] {
        var out: [RegionalCareGapEstimate] = []
        for item in items {
            let derived = newRegionalCareGapEstimate(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeRegionalCareGapEstimate(_ item: RegionalCareGapEstimate) -> String {
        return normalizeLenientProgramBaselineCode(item.code)
    }
}
