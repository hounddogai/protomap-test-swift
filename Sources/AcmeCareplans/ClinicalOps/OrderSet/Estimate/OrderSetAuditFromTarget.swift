import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffTargetsForAudit(_ items: [HandoffTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveOrderSetAuditsFromTarget(_ items: [HandoffTarget]) -> [OrderSetAudit] {
        var out: [OrderSetAudit] = []
        for item in items {
            let derived = newOrderSetAudit(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveOrderSetAudit(_ item: OrderSetAudit) -> String {
        return classifyHandoffGroup(item.measuredValue())
    }
}
