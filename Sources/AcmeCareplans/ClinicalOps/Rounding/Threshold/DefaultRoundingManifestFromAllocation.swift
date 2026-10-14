import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffAllocationsForManifest(_ items: [HandoffAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveDefaultRoundingManifestsFromAllocation(_ items: [HandoffAllocation]) -> [DefaultRoundingManifest] {
        var out: [DefaultRoundingManifest] = []
        for item in items {
            let derived = newDefaultRoundingManifest(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }
}
