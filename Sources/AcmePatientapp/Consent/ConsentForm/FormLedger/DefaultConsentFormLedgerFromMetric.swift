import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormMetricsForLedger(_ items: [ConsentFormMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveDefaultConsentFormLedgersFromMetric(_ items: [ConsentFormMetric]) -> [DefaultConsentFormLedger] {
        var out: [DefaultConsentFormLedger] = []
        for item in items {
            let derived = newDefaultConsentFormLedger(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeDefaultConsentFormLedger(_ item: DefaultConsentFormLedger) -> String {
        return consentFormPolicyBucket(item.projectedTotal())
    }
}
