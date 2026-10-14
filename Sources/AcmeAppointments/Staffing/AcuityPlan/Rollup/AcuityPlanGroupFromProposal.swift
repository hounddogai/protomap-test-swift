import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolProposalsForGroup(_ items: [FloatPoolProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveAcuityPlanGroupsFromProposal(_ items: [FloatPoolProposal]) -> [AcuityPlanGroup] {
        var out: [AcuityPlanGroup] = []
        for item in items {
            let derived = newAcuityPlanGroup(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignAcuityPlanGroup(_ item: AcuityPlanGroup) -> String {
        return normalizeFloatPoolProposalCode(item.code)
    }
}
