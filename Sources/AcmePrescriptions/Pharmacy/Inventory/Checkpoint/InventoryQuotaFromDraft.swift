import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSubstitutionDraftsForQuota(_ items: [SubstitutionDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveInventoryQuotasFromDraft(_ items: [SubstitutionDraft]) -> [InventoryQuota] {
        var out: [InventoryQuota] = []
        for item in items {
            let derived = newInventoryQuota(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateInventoryQuota(_ item: InventoryQuota) -> String {
        return classifyWeightedSubstitutionProposal(item.netTotal())
    }
}
