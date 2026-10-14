import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFallbackSubstitutionProposalsForWindow(_ items: [FallbackSubstitutionProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveInventoryWindowsFromProposal(_ items: [FallbackSubstitutionProposal]) -> [InventoryWindow] {
        var out: [InventoryWindow] = []
        for item in items {
            let derived = newInventoryWindow(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyInventoryWindow(_ item: InventoryWindow) -> Double {
        return fallbackSubstitutionProposalWeight(1, active: true)
    }
}
