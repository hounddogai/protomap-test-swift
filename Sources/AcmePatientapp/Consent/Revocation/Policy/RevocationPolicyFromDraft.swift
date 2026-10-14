import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureDraftsForPolicy(_ items: [DisclosureDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRevocationPoliciesFromDraft(_ items: [DisclosureDraft]) -> [RevocationPolicy] {
        var out: [RevocationPolicy] = []
        for item in items {
            let derived = newRevocationPolicy(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyRevocationPolicy(_ item: RevocationPolicy) -> String {
        return normalizeDisclosureDraftCode(item.code)
    }
}
