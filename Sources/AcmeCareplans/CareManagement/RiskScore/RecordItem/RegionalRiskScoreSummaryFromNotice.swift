import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeFallbackProgramNoticesForSummary(_ items: [FallbackProgramNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveRegionalRiskScoreSummariesFromNotice(_ items: [FallbackProgramNotice]) -> [RegionalRiskScoreSummary] {
        var out: [RegionalRiskScoreSummary] = []
        for item in items {
            let derived = newRegionalRiskScoreSummary(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankRegionalRiskScoreSummary(_ item: RegionalRiskScoreSummary) -> String {
        return normalizeFallbackProgramNoticeCode(item.code)
    }
}
