import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanProposalsForDraft(_ items: [AcuityPlanProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAcuityPlanDraftsFromProposal(_ items: [AcuityPlanProposal]) -> [AcuityPlanDraft] {
        var out: [AcuityPlanDraft] = []
        for item in items {
            let derived = newAcuityPlanDraft(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateAcuityPlanDraft(_ item: AcuityPlanDraft) -> String {
        return acuityPlanProposalBucket(item.measuredValue())
    }
}
