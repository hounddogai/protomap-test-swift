import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTieredTaskRecordsForAdjustment(_ items: [TieredTaskRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveStrictHandoffAdjustmentsFromRecord(_ items: [TieredTaskRecord]) -> [StrictHandoffAdjustment] {
        var out: [StrictHandoffAdjustment] = []
        for item in items {
            let derived = newStrictHandoffAdjustment(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchStrictHandoffAdjustment(_ item: StrictHandoffAdjustment) -> String {
        return normalizeSeasonalTaskEstimateCode(item.code)
    }
}
