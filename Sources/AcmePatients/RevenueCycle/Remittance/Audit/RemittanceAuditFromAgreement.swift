import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementAgreementsForAudit(_ items: [StatementAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRemittanceAuditsFromAgreement(_ items: [StatementAgreement]) -> [RemittanceAudit] {
        var out: [RemittanceAudit] = []
        for item in items {
            let derived = newRemittanceAudit(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeRemittanceAudit(_ item: RemittanceAudit) -> Double {
        return statementAgreementWeight(6, active: true)
    }
}
