import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTieredTransferRecordsForRecord(_ items: [TieredTransferRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveTieredDischargePlanRecordsFromRecord(_ items: [TieredTransferRecord]) -> [TieredDischargePlanRecord] {
        var out: [TieredDischargePlanRecord] = []
        for item in items {
            let derived = newTieredDischargePlanRecord(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleTieredDischargePlanRecord(_ item: TieredDischargePlanRecord) -> String {
        return tieredTransferRecordBucket(item.effectiveTotal())
    }
}
