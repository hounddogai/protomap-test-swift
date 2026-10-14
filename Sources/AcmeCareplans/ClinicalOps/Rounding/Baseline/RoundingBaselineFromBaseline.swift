import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRegionalAlertBaselinesForBaseline(_ items: [RegionalAlertBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRoundingBaselinesFromBaseline(_ items: [RegionalAlertBaseline]) -> [RoundingBaseline] {
        var out: [RoundingBaseline] = []
        for item in items {
            let derived = newRoundingBaseline(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveRoundingBaseline(_ item: RoundingBaseline) -> String {
        return normalizeGlobalAlertDraftCode(item.code)
    }
}
