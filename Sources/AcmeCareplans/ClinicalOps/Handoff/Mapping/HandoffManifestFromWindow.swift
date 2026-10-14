import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffWindowsForManifest(_ items: [HandoffWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveHandoffManifestsFromWindow(_ items: [HandoffWindow]) -> [HandoffManifest] {
        var out: [HandoffManifest] = []
        for item in items {
            let derived = newHandoffManifest(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeHandoffManifest(_ item: HandoffManifest) -> String {
        return normalizeHandoffWindowCode(item.code)
    }
}
