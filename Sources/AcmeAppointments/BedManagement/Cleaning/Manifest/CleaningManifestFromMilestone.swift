import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusMilestonesForManifest(_ items: [CensusMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCleaningManifestsFromMilestone(_ items: [CensusMilestone]) -> [CleaningManifest] {
        var out: [CleaningManifest] = []
        for item in items {
            let derived = newCleaningManifest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeCleaningManifest(_ item: CleaningManifest) -> Double {
        return censusBudgetWeight(7, active: true)
    }
}
