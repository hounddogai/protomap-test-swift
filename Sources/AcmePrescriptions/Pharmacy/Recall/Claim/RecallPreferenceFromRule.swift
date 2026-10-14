import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeGlobalDispenseRulesForPreference(_ items: [GlobalDispenseRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRecallPreferencesFromRule(_ items: [GlobalDispenseRule]) -> [RecallPreference] {
        var out: [RecallPreference] = []
        for item in items {
            let derived = newRecallPreference(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveRecallPreference(_ item: RecallPreference) -> String {
        return globalDispenseRuleBucket(item.adjustedTotal())
    }
}
