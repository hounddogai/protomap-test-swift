import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationPreferencesForNotice(_ items: [IsolationPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveAdaptiveCleaningNoticesFromPreference(_ items: [IsolationPreference]) -> [AdaptiveCleaningNotice] {
        var out: [AdaptiveCleaningNotice] = []
        for item in items {
            let derived = newAdaptiveCleaningNotice(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectAdaptiveCleaningNotice(_ item: AdaptiveCleaningNotice) -> String {
        return classifyIsolationMetric(item.projectedLoad())
    }
}
