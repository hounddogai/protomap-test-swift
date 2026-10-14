import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetNoticesForMilestone(_ items: [OrderSetNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveSeasonalHandoffMilestonesFromNotice(_ items: [OrderSetNotice]) -> [SeasonalHandoffMilestone] {
        var out: [SeasonalHandoffMilestone] = []
        for item in items {
            let derived = newSeasonalHandoffMilestone(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectSeasonalHandoffMilestone(_ item: SeasonalHandoffMilestone) -> String {
        return normalizeSeasonalOrderSetReviewCode(item.code)
    }
}
