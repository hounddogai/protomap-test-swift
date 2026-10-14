import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeBatchedCareGapBundlesForProposal(_ items: [BatchedCareGapBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveLenientGoalProposalsFromBundle(_ items: [BatchedCareGapBundle]) -> [LenientGoalProposal] {
        var out: [LenientGoalProposal] = []
        for item in items {
            let derived = newLenientGoalProposal(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreLenientGoalProposal(_ item: LenientGoalProposal) -> String {
        return normalizeBatchedCareGapBundleCode(item.code)
    }
}
