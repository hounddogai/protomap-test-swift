import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeDefaultRiskScoreThresholdsForWindow(_ items: [DefaultRiskScoreThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func derivePendingRiskScoreWindowsFromThreshold(_ items: [DefaultRiskScoreThreshold]) -> [PendingRiskScoreWindow] {
        var out: [PendingRiskScoreWindow] = []
        for item in items {
            let derived = newPendingRiskScoreWindow(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizePendingRiskScoreWindow(_ item: PendingRiskScoreWindow) -> String {
        return normalizeDefaultRiskScoreThresholdCode(item.code)
    }
}
