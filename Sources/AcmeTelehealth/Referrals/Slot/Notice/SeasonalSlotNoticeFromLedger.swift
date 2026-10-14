import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeStrictSlotLedgersForNotice(_ items: [StrictSlotLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveSeasonalSlotNoticesFromLedger(_ items: [StrictSlotLedger]) -> [SeasonalSlotNotice] {
        var out: [SeasonalSlotNotice] = []
        for item in items {
            let derived = newSeasonalSlotNotice(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateSeasonalSlotNotice(_ item: SeasonalSlotNotice) -> String {
        return normalizeSlotExceptionCode(item.code)
    }
}
