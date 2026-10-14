import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePrimaryTaskTemplatesForProposal(_ items: [PrimaryTaskTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalRoundingProposalsFromTemplate(_ items: [PrimaryTaskTemplate]) -> [RegionalRoundingProposal] {
        var out: [RegionalRoundingProposal] = []
        for item in items {
            let derived = newRegionalRoundingProposal(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateRegionalRoundingProposal(_ item: RegionalRoundingProposal) -> String {
        return classifyPrimaryTaskTemplate(item.netLoad())
    }
}
