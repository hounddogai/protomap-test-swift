import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeScheduledCareGapSnapshotsForWindow(_ items: [ScheduledCareGapSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveCareGapWindowsFromSnapshot(_ items: [ScheduledCareGapSnapshot]) -> [AdaptiveCareGapWindow] {
        var out: [AdaptiveCareGapWindow] = []
        for item in items {
            let derived = newAdaptiveCareGapWindow(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeAdaptiveCareGapWindow(_ item: AdaptiveCareGapWindow) -> String {
        return classifyCareGapReservation(item.effectiveExposure())
    }
}
