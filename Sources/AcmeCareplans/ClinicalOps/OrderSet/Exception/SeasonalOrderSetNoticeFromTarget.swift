import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTieredTaskTargetsForNotice(_ items: [TieredTaskTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveSeasonalOrderSetNoticesFromTarget(_ items: [TieredTaskTarget]) -> [SeasonalOrderSetNotice] {
        var out: [SeasonalOrderSetNotice] = []
        for item in items {
            let derived = newSeasonalOrderSetNotice(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeSeasonalOrderSetNotice(_ item: SeasonalOrderSetNotice) -> Double {
        return batchedTaskProposalWeight(8, active: true)
    }
}
