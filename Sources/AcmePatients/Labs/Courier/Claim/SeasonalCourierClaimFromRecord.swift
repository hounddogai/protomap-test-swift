import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierRecordsForClaim(_ items: [CourierRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalCourierClaimsFromRecord(_ items: [CourierRecord]) -> [SeasonalCourierClaim] {
        var out: [SeasonalCourierClaim] = []
        for item in items {
            let derived = newSeasonalCourierClaim(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeSeasonalCourierClaim(_ item: SeasonalCourierClaim) -> String {
        return classifyCappedCourierMetric(item.effectiveTotal())
    }
}
