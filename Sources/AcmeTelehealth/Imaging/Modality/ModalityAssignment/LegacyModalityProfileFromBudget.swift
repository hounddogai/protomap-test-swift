import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeAdaptiveCareProtocolBudgetsForProfile(_ items: [AdaptiveCareProtocolBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveLegacyModalityProfilesFromBudget(_ items: [AdaptiveCareProtocolBudget]) -> [LegacyModalityProfile] {
        var out: [LegacyModalityProfile] = []
        for item in items {
            let derived = newLegacyModalityProfile(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchLegacyModalityProfile(_ item: LegacyModalityProfile) -> String {
        return classifyAdaptiveCareProtocolBudget(item.measuredValue())
    }
}
