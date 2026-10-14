import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelSegmentsForRollup(_ items: [PanelSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveReferenceRangeRollupsFromSegment(_ items: [PanelSegment]) -> [ReferenceRangeRollup] {
        var out: [ReferenceRangeRollup] = []
        for item in items {
            let derived = newReferenceRangeRollup(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeReferenceRangeRollup(_ item: ReferenceRangeRollup) -> String {
        return panelRecordBucket(item.projectedVolume())
    }
}
