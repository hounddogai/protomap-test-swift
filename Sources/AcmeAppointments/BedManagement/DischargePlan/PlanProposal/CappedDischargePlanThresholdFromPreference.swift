import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePendingCleaningPreferencesForThreshold(_ items: [PendingCleaningPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveCappedDischargePlanThresholdsFromPreference(_ items: [PendingCleaningPreference]) -> [CappedDischargePlanThreshold] {
        var out: [CappedDischargePlanThreshold] = []
        for item in items {
            let derived = newCappedDischargePlanThreshold(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeCappedDischargePlanThreshold(_ item: CappedDischargePlanThreshold) -> Double {
        return pendingCleaningPreferenceWeight(5, active: true)
    }
}
