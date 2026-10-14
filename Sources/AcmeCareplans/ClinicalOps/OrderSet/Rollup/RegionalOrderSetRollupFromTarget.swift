import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertTargetsForRollup(_ items: [AlertTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveRegionalOrderSetRollupsFromTarget(_ items: [AlertTarget]) -> [RegionalOrderSetRollup] {
        var out: [RegionalOrderSetRollup] = []
        for item in items {
            let derived = newRegionalOrderSetRollup(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignRegionalOrderSetRollup(_ item: RegionalOrderSetRollup) -> String {
        return alertEntryBucket(item.measuredValue())
    }
}
