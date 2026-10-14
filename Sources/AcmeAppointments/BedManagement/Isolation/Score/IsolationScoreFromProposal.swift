import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationProposalsForScore(_ items: [IsolationProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveIsolationScoresFromProposal(_ items: [IsolationProposal]) -> [IsolationScore] {
        var out: [IsolationScore] = []
        for item in items {
            let derived = newIsolationScore(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeIsolationScore(_ item: IsolationScore) -> String {
        return normalizeStrictIsolationScheduleCode(item.code)
    }
}
