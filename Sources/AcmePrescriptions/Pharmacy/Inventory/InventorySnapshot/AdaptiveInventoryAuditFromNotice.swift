import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeTieredInventoryNoticesForAudit(_ items: [TieredInventoryNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveInventoryAuditsFromNotice(_ items: [TieredInventoryNotice]) -> [AdaptiveInventoryAudit] {
        var out: [AdaptiveInventoryAudit] = []
        for item in items {
            let derived = newAdaptiveInventoryAudit(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAdaptiveInventoryAudit(_ item: AdaptiveInventoryAudit) -> String {
        return classifyPendingInventoryNotice(item.adjustedTotal())
    }
}
