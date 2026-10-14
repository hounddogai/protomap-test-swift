import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLegacyAccessionMilestonesForMetric(_ items: [LegacyAccessionMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func derivePendingSpecimenMetricsFromMilestone(_ items: [LegacyAccessionMilestone]) -> [PendingSpecimenMetric] {
        var out: [PendingSpecimenMetric] = []
        for item in items {
            let derived = newPendingSpecimenMetric(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyPendingSpecimenMetric(_ item: PendingSpecimenMetric) -> Double {
        return accessionReservationWeight(4, active: true)
    }
}
