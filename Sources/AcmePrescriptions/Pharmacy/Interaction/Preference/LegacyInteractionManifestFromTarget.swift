import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeBatchedSubstitutionTargetsForManifest(_ items: [BatchedSubstitutionTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLegacyInteractionManifestsFromTarget(_ items: [BatchedSubstitutionTarget]) -> [LegacyInteractionManifest] {
        var out: [LegacyInteractionManifest] = []
        for item in items {
            let derived = newLegacyInteractionManifest(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectLegacyInteractionManifest(_ item: LegacyInteractionManifest) -> String {
        return classifyBatchedSubstitutionTarget(item.netTotal())
    }
}
