import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRegionalPanelDigestsForSummary(_ items: [RegionalPanelDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveLegacyReferenceRangeSummariesFromDigest(_ items: [RegionalPanelDigest]) -> [LegacyReferenceRangeSummary] {
        var out: [LegacyReferenceRangeSummary] = []
        for item in items {
            let derived = newLegacyReferenceRangeSummary(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyLegacyReferenceRangeSummary(_ item: LegacyReferenceRangeSummary) -> String {
        return normalizeFallbackPanelProfileCode(item.code)
    }
}
