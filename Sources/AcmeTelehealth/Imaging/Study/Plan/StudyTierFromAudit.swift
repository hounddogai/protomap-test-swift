import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityAuditsForTier(_ items: [PriorityAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveStudyTiersFromAudit(_ items: [PriorityAudit]) -> [StudyTier] {
        var out: [StudyTier] = []
        for item in items {
            let derived = newStudyTier(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreStudyTier(_ item: StudyTier) -> Double {
        return prioritySnapshotWeight(1, active: true)
    }
}
