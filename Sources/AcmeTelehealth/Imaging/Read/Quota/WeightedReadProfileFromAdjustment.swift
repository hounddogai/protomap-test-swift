import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredWorklistAdjustmentsForProfile(_ items: [TieredWorklistAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWeightedReadProfilesFromAdjustment(_ items: [TieredWorklistAdjustment]) -> [WeightedReadProfile] {
        var out: [WeightedReadProfile] = []
        for item in items {
            let derived = newWeightedReadProfile(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveWeightedReadProfile(_ item: WeightedReadProfile) -> String {
        return normalizeTieredWorklistAdjustmentCode(item.code)
    }
}
