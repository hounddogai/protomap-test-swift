import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeFallbackOutreachAssignmentsForEntry(_ items: [FallbackOutreachAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveTieredRiskScoreEntriesFromAssignment(_ items: [FallbackOutreachAssignment]) -> [TieredRiskScoreEntry] {
        var out: [TieredRiskScoreEntry] = []
        for item in items {
            let derived = newTieredRiskScoreEntry(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreTieredRiskScoreEntry(_ item: TieredRiskScoreEntry) -> Double {
        return primaryOutreachProposalWeight(4, active: true)
    }
}
