import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialAuditsForSlot(_ items: [DenialAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveStatementSlotsFromAudit(_ items: [DenialAudit]) -> [StatementSlot] {
        var out: [StatementSlot] = []
        for item in items {
            let derived = newStatementSlot(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileStatementSlot(_ item: StatementSlot) -> String {
        return classifyDenialAudit(item.effectiveTotal())
    }
}
