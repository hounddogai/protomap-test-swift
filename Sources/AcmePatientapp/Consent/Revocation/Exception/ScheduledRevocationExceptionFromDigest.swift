import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictLanguageDigestsForException(_ items: [StrictLanguageDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveScheduledRevocationExceptionsFromDigest(_ items: [StrictLanguageDigest]) -> [ScheduledRevocationException] {
        var out: [ScheduledRevocationException] = []
        for item in items {
            let derived = newScheduledRevocationException(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchScheduledRevocationException(_ item: ScheduledRevocationException) -> String {
        return classifyStrictLanguageDigest(item.measuredValue())
    }
}
