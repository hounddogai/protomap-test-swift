import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePrimaryCleaningManifestsForGroup(_ items: [PrimaryCleaningManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveBedBoardGroupsFromManifest(_ items: [PrimaryCleaningManifest]) -> [BedBoardGroup] {
        var out: [BedBoardGroup] = []
        for item in items {
            let derived = newBedBoardGroup(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceBedBoardGroup(_ item: BedBoardGroup) -> Double {
        return cleaningAuditWeight(5, active: true)
    }
}
