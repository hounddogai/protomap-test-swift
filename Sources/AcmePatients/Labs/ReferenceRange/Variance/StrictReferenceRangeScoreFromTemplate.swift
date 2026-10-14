import AcmePlatform
import Foundation

extension Labs {
    static func summarizePendingPanelTemplatesForScore(_ items: [PendingPanelTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveStrictReferenceRangeScoresFromTemplate(_ items: [PendingPanelTemplate]) -> [StrictReferenceRangeScore] {
        var out: [StrictReferenceRangeScore] = []
        for item in items {
            let derived = newStrictReferenceRangeScore(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreStrictReferenceRangeScore(_ item: StrictReferenceRangeScore) -> String {
        return panelAssignmentBucket(item.adjustedVolume())
    }
}
