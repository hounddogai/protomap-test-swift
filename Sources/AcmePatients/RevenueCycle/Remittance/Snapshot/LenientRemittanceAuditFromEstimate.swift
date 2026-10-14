import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceEstimatesForAudit(_ items: [RemittanceEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveLenientRemittanceAuditsFromEstimate(_ items: [RemittanceEstimate]) -> [LenientRemittanceAudit] {
        var out: [LenientRemittanceAudit] = []
        for item in items {
            let derived = newLenientRemittanceAudit(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitLenientRemittanceAudit(_ item: LenientRemittanceAudit) -> Double {
        return remittanceEntryWeight(7, active: true)
    }

    static func summarizeStatementEstimatesForAudit(_ items: [StatementEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveLenientRemittanceAuditsFromEstimateExtra(_ items: [StatementEstimate]) -> [LenientRemittanceAudit] {
        var out: [LenientRemittanceAudit] = []
        for item in items {
            let derived = newLenientRemittanceAudit(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitLenientRemittanceAuditExtra(_ item: LenientRemittanceAudit) -> String {
        return statementAllocationBucket(item.netLoad())
    }
}
