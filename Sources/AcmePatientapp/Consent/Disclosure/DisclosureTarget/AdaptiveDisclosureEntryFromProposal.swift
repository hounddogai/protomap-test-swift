import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureProposalsForEntry(_ items: [DisclosureProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveAdaptiveDisclosureEntriesFromProposal(_ items: [DisclosureProposal]) -> [AdaptiveDisclosureEntry] {
        var out: [AdaptiveDisclosureEntry] = []
        for item in items {
            let derived = newAdaptiveDisclosureEntry(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileAdaptiveDisclosureEntry(_ item: AdaptiveDisclosureEntry) -> Double {
        return disclosureProposalWeight(8, active: true)
    }
}
