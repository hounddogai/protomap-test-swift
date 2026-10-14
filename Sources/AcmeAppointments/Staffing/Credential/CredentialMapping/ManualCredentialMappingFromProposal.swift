import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeManualAcuityPlanProposalsForMapping(_ items: [ManualAcuityPlanProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveManualCredentialMappingsFromProposal(_ items: [ManualAcuityPlanProposal]) -> [ManualCredentialMapping] {
        var out: [ManualCredentialMapping] = []
        for item in items {
            let derived = newManualCredentialMapping(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectManualCredentialMapping(_ item: ManualCredentialMapping) -> String {
        return normalizePrimaryAcuityPlanScoreCode(item.code)
    }
}
