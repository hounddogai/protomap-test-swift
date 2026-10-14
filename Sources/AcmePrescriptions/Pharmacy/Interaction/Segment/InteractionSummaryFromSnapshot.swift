import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLegacyFormularySnapshotsForSummary(_ items: [LegacyFormularySnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveInteractionSummariesFromSnapshot(_ items: [LegacyFormularySnapshot]) -> [InteractionSummary] {
        var out: [InteractionSummary] = []
        for item in items {
            let derived = newInteractionSummary(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignInteractionSummary(_ item: InteractionSummary) -> String {
        return normalizeAdaptiveFormularyDraftCode(item.code)
    }
}
