import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionManifestsForBatch(_ items: [AccessionManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveAdaptiveSpecimenBatchesFromManifest(_ items: [AccessionManifest]) -> [AdaptiveSpecimenBatch] {
        var out: [AdaptiveSpecimenBatch] = []
        for item in items {
            let derived = newAdaptiveSpecimenBatch(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateAdaptiveSpecimenBatch(_ item: AdaptiveSpecimenBatch) -> String {
        return classifyRollingAccessionBatch(item.netExposure())
    }
}
