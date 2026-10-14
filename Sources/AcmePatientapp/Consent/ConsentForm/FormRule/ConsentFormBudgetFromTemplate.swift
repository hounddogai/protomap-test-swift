import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormTemplatesForBudget(_ items: [ConsentFormTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveConsentFormBudgetsFromTemplate(_ items: [ConsentFormTemplate]) -> [ConsentFormBudget] {
        var out: [ConsentFormBudget] = []
        for item in items {
            let derived = newConsentFormBudget(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeConsentFormBudget(_ item: ConsentFormBudget) -> String {
        return regionalConsentFormThresholdBucket(item.projectedTotal())
    }
}
