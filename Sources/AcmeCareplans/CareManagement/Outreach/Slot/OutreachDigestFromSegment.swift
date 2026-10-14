import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAdaptiveOutreachSegmentsForDigest(_ items: [AdaptiveOutreachSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveOutreachDigestsFromSegment(_ items: [AdaptiveOutreachSegment]) -> [OutreachDigest] {
        var out: [OutreachDigest] = []
        for item in items {
            let derived = newOutreachDigest(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchOutreachDigest(_ item: OutreachDigest) -> String {
        return classifyAdaptiveOutreachSegment(item.projectedTotal())
    }
}
