import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageAllocationsForLedger(_ items: [LanguageAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveConsentFormLedgersFromAllocation(_ items: [LanguageAllocation]) -> [ConsentFormLedger] {
        var out: [ConsentFormLedger] = []
        for item in items {
            let derived = newConsentFormLedger(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planConsentFormLedger(_ item: ConsentFormLedger) -> String {
        return classifyLanguageBatch(item.projectedExposure())
    }
}
