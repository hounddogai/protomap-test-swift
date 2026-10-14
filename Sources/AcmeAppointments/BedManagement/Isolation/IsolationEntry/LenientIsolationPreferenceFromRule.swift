import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeScheduledBedBoardRulesForPreference(_ items: [ScheduledBedBoardRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveLenientIsolationPreferencesFromRule(_ items: [ScheduledBedBoardRule]) -> [LenientIsolationPreference] {
        var out: [LenientIsolationPreference] = []
        for item in items {
            let derived = newLenientIsolationPreference(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeLenientIsolationPreference(_ item: LenientIsolationPreference) -> String {
        return classifyCappedBedBoardReservation(item.weightedValue())
    }
}
