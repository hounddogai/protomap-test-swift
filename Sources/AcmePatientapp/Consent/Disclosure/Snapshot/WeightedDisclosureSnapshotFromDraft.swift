import AcmePlatform
import Foundation

extension Consent {
    static func summarizeFallbackDisclosureDraftsForSnapshot(_ items: [FallbackDisclosureDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWeightedDisclosureSnapshotsFromDraft(_ items: [FallbackDisclosureDraft]) -> [WeightedDisclosureSnapshot] {
        var out: [WeightedDisclosureSnapshot] = []
        for item in items {
            let derived = newWeightedDisclosureSnapshot(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeWeightedDisclosureSnapshot(_ item: WeightedDisclosureSnapshot) -> String {
        return classifyAdaptiveDisclosureSegment(item.effectiveVolume())
    }
}
