import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeFallbackOutreachAuditsForEntry(_ items: [FallbackOutreachAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveGlobalGoalEntriesFromAudit(_ items: [FallbackOutreachAudit]) -> [GlobalGoalEntry] {
        var out: [GlobalGoalEntry] = []
        for item in items {
            let derived = newGlobalGoalEntry(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyGlobalGoalEntry(_ item: GlobalGoalEntry) -> String {
        return outreachDigestBucket(item.projectedTotal())
    }
}
