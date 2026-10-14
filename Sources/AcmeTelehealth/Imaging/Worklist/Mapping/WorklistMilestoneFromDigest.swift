import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCappedReadDigestsForMilestone(_ items: [CappedReadDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveWorklistMilestonesFromDigest(_ items: [CappedReadDigest]) -> [WorklistMilestone] {
        var out: [WorklistMilestone] = []
        for item in items {
            let derived = newWorklistMilestone(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitWorklistMilestone(_ item: WorklistMilestone) -> String {
        return classifyCappedReadDigest(item.projectedLoad())
    }
}
