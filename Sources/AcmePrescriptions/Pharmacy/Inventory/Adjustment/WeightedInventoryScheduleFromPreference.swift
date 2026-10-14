import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeGlobalFormularyPreferencesForSchedule(_ items: [GlobalFormularyPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveWeightedInventorySchedulesFromPreference(_ items: [GlobalFormularyPreference]) -> [WeightedInventorySchedule] {
        var out: [WeightedInventorySchedule] = []
        for item in items {
            let derived = newWeightedInventorySchedule(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateWeightedInventorySchedule(_ item: WeightedInventorySchedule) -> String {
        return scheduledFormularyMilestoneBucket(item.weightedValue())
    }
}
