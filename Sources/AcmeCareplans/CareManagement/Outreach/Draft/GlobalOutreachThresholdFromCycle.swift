import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLegacyGoalCyclesForThreshold(_ items: [LegacyGoalCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveGlobalOutreachThresholdsFromCycle(_ items: [LegacyGoalCycle]) -> [GlobalOutreachThreshold] {
        var out: [GlobalOutreachThreshold] = []
        for item in items {
            let derived = newGlobalOutreachThreshold(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreGlobalOutreachThreshold(_ item: GlobalOutreachThreshold) -> String {
        return normalizeLegacyGoalCycleCode(item.code)
    }
}
