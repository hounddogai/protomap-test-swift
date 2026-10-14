import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningLedgersForRequest(_ items: [CleaningLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveDischargePlanRequestsFromLedger(_ items: [CleaningLedger]) -> [DischargePlanRequest] {
        var out: [DischargePlanRequest] = []
        for item in items {
            let derived = newDischargePlanRequest(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planDischargePlanRequest(_ item: DischargePlanRequest) -> String {
        return normalizeCleaningAdjustmentCode(item.code)
    }
}
