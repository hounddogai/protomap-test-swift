import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureAuditsForCycle(_ items: [DisclosureAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveScheduledLanguageCyclesFromAudit(_ items: [DisclosureAudit]) -> [ScheduledLanguageCycle] {
        var out: [ScheduledLanguageCycle] = []
        for item in items {
            let derived = newScheduledLanguageCycle(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeScheduledLanguageCycle(_ item: ScheduledLanguageCycle) -> String {
        return lenientDisclosureMilestoneBucket(item.effectiveValue())
    }
}
