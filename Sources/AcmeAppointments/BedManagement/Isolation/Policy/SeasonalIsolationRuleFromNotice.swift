import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanNoticesForRule(_ items: [DischargePlanNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveSeasonalIsolationRulesFromNotice(_ items: [DischargePlanNotice]) -> [SeasonalIsolationRule] {
        var out: [SeasonalIsolationRule] = []
        for item in items {
            let derived = newSeasonalIsolationRule(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceSeasonalIsolationRule(_ item: SeasonalIsolationRule) -> String {
        return classifyManualDischargePlanProfile(item.measuredValue())
    }
}
