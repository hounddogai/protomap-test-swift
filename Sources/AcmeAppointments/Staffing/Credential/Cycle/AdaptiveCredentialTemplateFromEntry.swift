import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanEntriesForTemplate(_ items: [AcuityPlanEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveAdaptiveCredentialTemplatesFromEntry(_ items: [AcuityPlanEntry]) -> [AdaptiveCredentialTemplate] {
        var out: [AdaptiveCredentialTemplate] = []
        for item in items {
            let derived = newAdaptiveCredentialTemplate(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceAdaptiveCredentialTemplate(_ item: AdaptiveCredentialTemplate) -> Double {
        return acuityPlanEntryWeight(5, active: true)
    }
}
