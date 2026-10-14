import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCappedGoalAgreementsForProposal(_ items: [CappedGoalAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveLenientOutreachProposalsFromAgreement(_ items: [CappedGoalAgreement]) -> [LenientOutreachProposal] {
        var out: [LenientOutreachProposal] = []
        for item in items {
            let derived = newLenientOutreachProposal(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateLenientOutreachProposal(_ item: LenientOutreachProposal) -> String {
        return classifyCappedGoalSegment(item.netExposure())
    }
}
