import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeRequestsForCheckpoint(_ items: [ReferenceRangeRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func derivePanelCheckpointsFromRequest(_ items: [ReferenceRangeRequest]) -> [PanelCheckpoint] {
        var out: [PanelCheckpoint] = []
        for item in items {
            let derived = newPanelCheckpoint(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizePanelCheckpoint(_ item: PanelCheckpoint) -> String {
        return classifyRollingReferenceRangeRollup(item.netValue())
    }
}
