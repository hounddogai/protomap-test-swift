import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryReferralExceptionsForRecord(_ items: [PrimaryReferralException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBatchedSlotRecordsFromException(_ items: [PrimaryReferralException]) -> [BatchedSlotRecord] {
        var out: [BatchedSlotRecord] = []
        for item in items {
            let derived = newBatchedSlotRecord(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankBatchedSlotRecord(_ item: BatchedSlotRecord) -> String {
        return normalizeSeasonalReferralAuditCode(item.code)
    }
}
