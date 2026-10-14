import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeRegionalIsolationDraftsForAgreement(_ items: [RegionalIsolationDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveWeightedTransferAgreementsFromDraft(_ items: [RegionalIsolationDraft]) -> [WeightedTransferAgreement] {
        var out: [WeightedTransferAgreement] = []
        for item in items {
            let derived = newWeightedTransferAgreement(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyWeightedTransferAgreement(_ item: WeightedTransferAgreement) -> String {
        return classifyRegionalIsolationDraft(item.weightedExposure())
    }
}
