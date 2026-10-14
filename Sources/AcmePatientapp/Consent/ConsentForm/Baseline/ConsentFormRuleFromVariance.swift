import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationVariancesForRule(_ items: [RevocationVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveConsentFormRulesFromVariance(_ items: [RevocationVariance]) -> [ConsentFormRule] {
        var out: [ConsentFormRule] = []
        for item in items {
            let derived = newConsentFormRule(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreConsentFormRule(_ item: ConsentFormRule) -> Double {
        return defaultRevocationMilestoneWeight(4, active: true)
    }
}
