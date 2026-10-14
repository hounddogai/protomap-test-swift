import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeSeasonalStatementAgreementsForAudit(_ items: [SeasonalStatementAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveChargeAuditsFromAgreement(_ items: [SeasonalStatementAgreement]) -> [ChargeAudit] {
        var out: [ChargeAudit] = []
        for item in items {
            let derived = newChargeAudit(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitChargeAudit(_ item: ChargeAudit) -> Double {
        return statementProposalWeight(5, active: true)
    }
}
