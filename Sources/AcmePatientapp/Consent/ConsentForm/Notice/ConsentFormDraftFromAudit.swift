import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLegacyConsentFormAuditsForDraft(_ items: [LegacyConsentFormAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveConsentFormDraftsFromAudit(_ items: [LegacyConsentFormAudit]) -> [ConsentFormDraft] {
        var out: [ConsentFormDraft] = []
        for item in items {
            let derived = newConsentFormDraft(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyConsentFormDraft(_ item: ConsentFormDraft) -> String {
        return normalizeConsentFormScoreCode(item.code)
    }
}
