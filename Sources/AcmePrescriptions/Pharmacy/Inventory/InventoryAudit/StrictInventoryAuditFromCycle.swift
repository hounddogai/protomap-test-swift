import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallCyclesForAudit(_ items: [RecallCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveStrictInventoryAuditsFromCycle(_ items: [RecallCycle]) -> [StrictInventoryAudit] {
        var out: [StrictInventoryAudit] = []
        for item in items {
            let derived = newStrictInventoryAudit(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreStrictInventoryAudit(_ item: StrictInventoryAudit) -> String {
        return normalizePendingRecallRequestCode(item.code)
    }
}
