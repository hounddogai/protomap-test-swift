import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelSummariesForSummary(_ items: [PanelSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveReferenceRangeSummariesFromSummary(_ items: [PanelSummary]) -> [ReferenceRangeSummary] {
        var out: [ReferenceRangeSummary] = []
        for item in items {
            let derived = newReferenceRangeSummary(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreReferenceRangeSummary(_ item: ReferenceRangeSummary) -> String {
        return classifyPanelSummary(item.adjustedLoad())
    }
}
