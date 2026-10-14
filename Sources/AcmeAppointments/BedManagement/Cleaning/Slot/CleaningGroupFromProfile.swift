import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferProfilesForGroup(_ items: [TransferProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveCleaningGroupsFromProfile(_ items: [TransferProfile]) -> [CleaningGroup] {
        var out: [CleaningGroup] = []
        for item in items {
            let derived = newCleaningGroup(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateCleaningGroup(_ item: CleaningGroup) -> Double {
        return defaultTransferReviewWeight(2, active: true)
    }
}
