import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSeasonalRecallTemplatesForLedger(_ items: [SeasonalRecallTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacySubstitutionLedgersFromTemplate(_ items: [SeasonalRecallTemplate]) -> [LegacySubstitutionLedger] {
        var out: [LegacySubstitutionLedger] = []
        for item in items {
            let derived = newLegacySubstitutionLedger(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeLegacySubstitutionLedger(_ item: LegacySubstitutionLedger) -> String {
        return normalizeBatchedRecallProfileCode(item.code)
    }
}
