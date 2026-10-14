import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferDraftsForPolicy(_ items: [TransferDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCleaningPoliciesFromDraft(_ items: [TransferDraft]) -> [CleaningPolicy] {
        var out: [CleaningPolicy] = []
        for item in items {
            let derived = newCleaningPolicy(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeCleaningPolicy(_ item: CleaningPolicy) -> String {
        return classifyTransferDraft(item.netTotal())
    }
}
