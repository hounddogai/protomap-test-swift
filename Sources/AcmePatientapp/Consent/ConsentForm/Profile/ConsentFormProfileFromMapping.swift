import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureMappingsForProfile(_ items: [DisclosureMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveConsentFormProfilesFromMapping(_ items: [DisclosureMapping]) -> [ConsentFormProfile] {
        var out: [ConsentFormProfile] = []
        for item in items {
            let derived = newConsentFormProfile(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankConsentFormProfile(_ item: ConsentFormProfile) -> String {
        return normalizeGlobalDisclosureBaselineCode(item.code)
    }
}
