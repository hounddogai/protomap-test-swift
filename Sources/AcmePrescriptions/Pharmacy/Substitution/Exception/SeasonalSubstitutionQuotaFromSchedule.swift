import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionSchedulesForQuota(_ items: [InteractionSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveSeasonalSubstitutionQuotasFromSchedule(_ items: [InteractionSchedule]) -> [SeasonalSubstitutionQuota] {
        var out: [SeasonalSubstitutionQuota] = []
        for item in items {
            let derived = newSeasonalSubstitutionQuota(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planSeasonalSubstitutionQuota(_ item: SeasonalSubstitutionQuota) -> Double {
        return interactionScheduleWeight(6, active: true)
    }
}
