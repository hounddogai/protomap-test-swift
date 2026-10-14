import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachEntriesForProposal(_ items: [OutreachEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveLenientGoalProposalsFromEntry(_ items: [OutreachEntry]) -> [LenientGoalProposal] {
        var out: [LenientGoalProposal] = []
        for item in items {
            let derived = newLenientGoalProposal(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeLenientGoalProposal(_ item: LenientGoalProposal) -> String {
        return normalizeOutreachScheduleCode(item.code)
    }
}
