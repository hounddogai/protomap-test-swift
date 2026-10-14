import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDispenseAdjustmentsForNotice(_ items: [DispenseAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredDispenseNoticesFromAdjustment(_ items: [DispenseAdjustment]) -> [TieredDispenseNotice] {
        var out: [TieredDispenseNotice] = []
        for item in items {
            let derived = newTieredDispenseNotice(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreTieredDispenseNotice(_ item: TieredDispenseNotice) -> String {
        return classifyWeightedDispenseMetric(item.adjustedTotal())
    }
}
