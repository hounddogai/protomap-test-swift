import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSeasonalClosureBundlesForRecord(_ items: [SeasonalClosureBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveScheduledSlotRecordsFromBundle(_ items: [SeasonalClosureBundle]) -> [ScheduledSlotRecord] {
        var out: [ScheduledSlotRecord] = []
        for item in items {
            let derived = newScheduledSlotRecord(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planScheduledSlotRecord(_ item: ScheduledSlotRecord) -> Double {
        return regionalClosureLedgerWeight(3, active: true)
    }
}
