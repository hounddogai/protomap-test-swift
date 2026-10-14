import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageAuditsForEstimate(_ items: [LanguageAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveManualRevocationEstimatesFromAudit(_ items: [LanguageAudit]) -> [ManualRevocationEstimate] {
        var out: [ManualRevocationEstimate] = []
        for item in items {
            let derived = newManualRevocationEstimate(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectManualRevocationEstimate(_ item: ManualRevocationEstimate) -> Double {
        return languageAuditWeight(7, active: true)
    }
}
