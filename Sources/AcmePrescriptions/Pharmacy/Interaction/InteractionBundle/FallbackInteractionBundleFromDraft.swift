import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeTieredInteractionDraftsForBundle(_ items: [TieredInteractionDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveFallbackInteractionBundlesFromDraft(_ items: [TieredInteractionDraft]) -> [FallbackInteractionBundle] {
        var out: [FallbackInteractionBundle] = []
        for item in items {
            let derived = newFallbackInteractionBundle(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyFallbackInteractionBundleExtra(_ item: FallbackInteractionBundle) -> String {
        return classifyTieredInteractionDraft(item.adjustedTotal())
    }
}
