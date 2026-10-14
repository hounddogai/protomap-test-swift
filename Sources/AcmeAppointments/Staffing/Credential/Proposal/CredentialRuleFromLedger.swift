import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolLedgersForRule(_ items: [FloatPoolLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveCredentialRulesFromLedger(_ items: [FloatPoolLedger]) -> [CredentialRule] {
        var out: [CredentialRule] = []
        for item in items {
            let derived = newCredentialRule(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateCredentialRule(_ item: CredentialRule) -> String {
        return normalizeRollingFloatPoolEstimateCode(item.code)
    }
}
