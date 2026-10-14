import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeDraftsForRecord(_ items: [ReferenceRangeDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePanelRecordsFromDraft(_ items: [ReferenceRangeDraft]) -> [PanelRecord] {
        var out: [PanelRecord] = []
        for item in items {
            let derived = newPanelRecord(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchPanelRecord(_ item: PanelRecord) -> Double {
        return referenceRangeDraftWeight(7, active: true)
    }
}
