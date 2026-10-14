import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreQuotasForNotice(_ items: [RiskScoreQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func derivePendingProgramNoticesFromQuota(_ items: [RiskScoreQuota]) -> [PendingProgramNotice] {
        var out: [PendingProgramNotice] = []
        for item in items {
            let derived = newPendingProgramNotice(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyPendingProgramNotice(_ item: PendingProgramNotice) -> String {
        return normalizeRiskScoreDigestCode(item.code)
    }
}
