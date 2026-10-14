import AcmePlatform
import Foundation

extension Consent {
    static func summarizePrimaryDisclosureSummariesForTemplate(_ items: [PrimaryDisclosureSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveConsentFormTemplatesFromSummary(_ items: [PrimaryDisclosureSummary]) -> [ConsentFormTemplate] {
        var out: [ConsentFormTemplate] = []
        for item in items {
            let derived = newConsentFormTemplate(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceConsentFormTemplate(_ item: ConsentFormTemplate) -> String {
        return classifyCappedDisclosureLedger(item.measuredValue())
    }
}
