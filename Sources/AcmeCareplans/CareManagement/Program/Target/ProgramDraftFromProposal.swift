import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreProposalsForDraft(_ items: [RiskScoreProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveProgramDraftsFromProposal(_ items: [RiskScoreProposal]) -> [ProgramDraft] {
        var out: [ProgramDraft] = []
        for item in items {
            let derived = newProgramDraft(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchProgramDraft(_ item: ProgramDraft) -> String {
        return classifyRiskScoreLedger(item.measuredValue())
    }
}
