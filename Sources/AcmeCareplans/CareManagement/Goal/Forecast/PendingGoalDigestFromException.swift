import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAdaptiveProgramExceptionsForDigest(_ items: [AdaptiveProgramException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func derivePendingGoalDigestsFromException(_ items: [AdaptiveProgramException]) -> [PendingGoalDigest] {
        var out: [PendingGoalDigest] = []
        for item in items {
            let derived = newPendingGoalDigest(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyPendingGoalDigestExtra(_ item: PendingGoalDigest) -> String {
        return normalizeLenientProgramBaselineCode(item.code)
    }
}
