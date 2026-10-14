import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryOvertimeSummariesForDigest(_ items: [PrimaryOvertimeSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveTieredShiftDigestsFromSummary(_ items: [PrimaryOvertimeSummary]) -> [TieredShiftDigest] {
        var out: [TieredShiftDigest] = []
        for item in items {
            let derived = newTieredShiftDigest(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateTieredShiftDigest(_ item: TieredShiftDigest) -> String {
        return normalizeSeasonalOvertimeDigestCode(item.code)
    }
}
