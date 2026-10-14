import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeSeasonalStudyBatchesForRule(_ items: [SeasonalStudyBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledStudyRulesFromBatch(_ items: [SeasonalStudyBatch]) -> [ScheduledStudyRule] {
        var out: [ScheduledStudyRule] = []
        for item in items {
            let derived = newScheduledStudyRule(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchScheduledStudyRule(_ item: ScheduledStudyRule) -> String {
        return classifySeasonalStudyBatch(item.measuredValue())
    }
}
