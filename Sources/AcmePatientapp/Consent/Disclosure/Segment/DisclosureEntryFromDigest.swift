import AcmePlatform
import Foundation

extension Consent {
    static func summarizeSeasonalDisclosureDigestsForEntry(_ items: [SeasonalDisclosureDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveDisclosureEntriesFromDigest(_ items: [SeasonalDisclosureDigest]) -> [DisclosureEntry] {
        var out: [DisclosureEntry] = []
        for item in items {
            let derived = newDisclosureEntry(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveDisclosureEntry(_ item: DisclosureEntry) -> String {
        return normalizeSeasonalDisclosureDigestCode(item.code)
    }
}
