import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyMilestonesForProposal(_ items: [FormularyMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveInventoryProposalsFromMilestone(_ items: [FormularyMilestone]) -> [InventoryProposal] {
        var out: [InventoryProposal] = []
        for item in items {
            let derived = newInventoryProposal(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateInventoryProposal(_ item: InventoryProposal) -> String {
        return normalizeRegionalFormularyMilestoneCode(item.code)
    }
}
