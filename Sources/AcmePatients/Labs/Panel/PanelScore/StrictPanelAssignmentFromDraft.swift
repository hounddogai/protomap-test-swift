import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelDraftsForAssignment(_ items: [PanelDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveStrictPanelAssignmentsFromDraft(_ items: [PanelDraft]) -> [StrictPanelAssignment] {
        var out: [StrictPanelAssignment] = []
        for item in items {
            let derived = newStrictPanelAssignment(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyStrictPanelAssignment(_ item: StrictPanelAssignment) -> String {
        return tieredPanelSlotBucket(item.projectedExposure())
    }
}
