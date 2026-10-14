import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelSegmentsForAdjustment(_ items: [PanelSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveAccessionAdjustmentsFromSegment(_ items: [PanelSegment]) -> [AccessionAdjustment] {
        var out: [AccessionAdjustment] = []
        for item in items {
            let derived = newAccessionAdjustment(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreAccessionAdjustment(_ item: AccessionAdjustment) -> String {
        return panelRecordBucket(item.projectedValue())
    }
}
