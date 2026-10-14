import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTieredRoundingScoresForTemplate(_ items: [TieredRoundingScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveScheduledAlertTemplatesFromScore(_ items: [TieredRoundingScore]) -> [ScheduledAlertTemplate] {
        var out: [ScheduledAlertTemplate] = []
        for item in items {
            let derived = newScheduledAlertTemplate(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignScheduledAlertTemplate(_ item: ScheduledAlertTemplate) -> String {
        return classifyTieredRoundingScore(item.weightedVolume())
    }
}
