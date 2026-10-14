import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePendingModalitySegmentsForGroup(_ items: [PendingModalitySegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveModalityGroupsFromSegment(_ items: [PendingModalitySegment]) -> [ModalityGroup] {
        var out: [ModalityGroup] = []
        for item in items {
            let derived = newModalityGroup(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planModalityGroup(_ item: ModalityGroup) -> Double {
        return pendingModalitySegmentWeight(4, active: true)
    }
}
