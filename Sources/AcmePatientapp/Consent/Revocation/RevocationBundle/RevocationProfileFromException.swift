import AcmePlatform
import Foundation

extension Consent {
    static func summarizeAdaptiveRevocationExceptionsForProfile(_ items: [AdaptiveRevocationException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRevocationProfilesFromException(_ items: [AdaptiveRevocationException]) -> [RevocationProfile] {
        var out: [RevocationProfile] = []
        for item in items {
            let derived = newRevocationProfile(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeRevocationProfile(_ item: RevocationProfile) -> String {
        return classifyRevocationRollup(item.measuredValue())
    }
}
