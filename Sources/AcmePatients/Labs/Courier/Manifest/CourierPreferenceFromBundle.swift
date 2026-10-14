import AcmePlatform
import Foundation

extension Labs {
    static func summarizePrimaryReferenceRangeBundlesForPreference(_ items: [PrimaryReferenceRangeBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveCourierPreferencesFromBundle(_ items: [PrimaryReferenceRangeBundle]) -> [CourierPreference] {
        var out: [CourierPreference] = []
        for item in items {
            let derived = newCourierPreference(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleCourierPreference(_ item: CourierPreference) -> String {
        return normalizeFallbackReferenceRangeBatchCode(item.code)
    }
}
