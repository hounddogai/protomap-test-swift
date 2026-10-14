import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureDraftsForAgreement(_ items: [DisclosureDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyDisclosureAgreementsFromDraft(_ items: [DisclosureDraft]) -> [LegacyDisclosureAgreement] {
        var out: [LegacyDisclosureAgreement] = []
        for item in items {
            let derived = newLegacyDisclosureAgreement(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceLegacyDisclosureAgreement(_ item: LegacyDisclosureAgreement) -> String {
        return normalizeDisclosureDraftCode(item.code)
    }
}
