import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormAdjustmentsForLedger(_ items: [ConsentFormAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveConsentFormLedgersFromAdjustment(_ items: [ConsentFormAdjustment]) -> [ConsentFormLedger] {
        var out: [ConsentFormLedger] = []
        for item in items {
            let derived = newConsentFormLedger(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeConsentFormLedger(_ item: ConsentFormLedger) -> String {
        return consentFormWindowBucket(item.projectedExposure())
    }
}
