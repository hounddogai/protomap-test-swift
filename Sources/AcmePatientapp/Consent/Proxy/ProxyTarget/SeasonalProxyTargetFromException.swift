import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureExceptionsForTarget(_ items: [DisclosureException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveSeasonalProxyTargetsFromException(_ items: [DisclosureException]) -> [SeasonalProxyTarget] {
        var out: [SeasonalProxyTarget] = []
        for item in items {
            let derived = newSeasonalProxyTarget(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateSeasonalProxyTarget(_ item: SeasonalProxyTarget) -> String {
        return normalizeDisclosureExceptionCode(item.code)
    }
}
