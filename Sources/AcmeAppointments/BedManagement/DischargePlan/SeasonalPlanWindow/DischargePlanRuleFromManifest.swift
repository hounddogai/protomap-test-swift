import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeSeasonalCleaningManifestsForRule(_ items: [SeasonalCleaningManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveDischargePlanRulesFromManifest(_ items: [SeasonalCleaningManifest]) -> [DischargePlanRule] {
        var out: [DischargePlanRule] = []
        for item in items {
            let derived = newDischargePlanRule(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateDischargePlanRule(_ item: DischargePlanRule) -> String {
        return normalizeCleaningSnapshotCode(item.code)
    }
}
