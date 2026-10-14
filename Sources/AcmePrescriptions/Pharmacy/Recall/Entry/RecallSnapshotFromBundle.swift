import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionBundlesForSnapshot(_ items: [InteractionBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveRecallSnapshotsFromBundle(_ items: [InteractionBundle]) -> [RecallSnapshot] {
        var out: [RecallSnapshot] = []
        for item in items {
            let derived = newRecallSnapshot(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyRecallSnapshot(_ item: RecallSnapshot) -> Double {
        return interactionBundleWeight(8, active: true)
    }
}
