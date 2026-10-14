import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationSummariesForTemplate(_ items: [IsolationSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveLegacyBedBoardTemplatesFromSummary(_ items: [IsolationSummary]) -> [LegacyBedBoardTemplate] {
        var out: [LegacyBedBoardTemplate] = []
        for item in items {
            let derived = newLegacyBedBoardTemplate(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitLegacyBedBoardTemplate(_ item: LegacyBedBoardTemplate) -> String {
        return normalizeIsolationSummaryCode(item.code)
    }
}
