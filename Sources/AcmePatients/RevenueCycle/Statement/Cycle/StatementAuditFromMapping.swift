import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceMappingsForAudit(_ items: [RemittanceMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveStatementAuditsFromMapping(_ items: [RemittanceMapping]) -> [StatementAudit] {
        var out: [StatementAudit] = []
        for item in items {
            let derived = newStatementAudit(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignStatementAudit(_ item: StatementAudit) -> String {
        return classifyManualRemittanceSnapshot(item.effectiveLoad())
    }
}
