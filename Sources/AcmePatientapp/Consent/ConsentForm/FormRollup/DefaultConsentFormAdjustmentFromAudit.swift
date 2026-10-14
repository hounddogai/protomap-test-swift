import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessAuditsForAdjustment(_ items: [WitnessAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultConsentFormAdjustmentsFromAudit(_ items: [WitnessAudit]) -> [DefaultConsentFormAdjustment] {
        var out: [DefaultConsentFormAdjustment] = []
        for item in items {
            let derived = newDefaultConsentFormAdjustment(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyDefaultConsentFormAdjustment(_ item: DefaultConsentFormAdjustment) -> String {
        return witnessClaimBucket(item.measuredValue())
    }
}
