import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeGlobalInventoryCyclesForRecord(_ items: [GlobalInventoryCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveCappedSubstitutionRecordsFromCycle(_ items: [GlobalInventoryCycle]) -> [CappedSubstitutionRecord] {
        var out: [CappedSubstitutionRecord] = []
        for item in items {
            let derived = newCappedSubstitutionRecord(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveCappedSubstitutionRecord(_ item: CappedSubstitutionRecord) -> String {
        return lenientInventoryOverrideBucket(item.adjustedTotal())
    }
}
