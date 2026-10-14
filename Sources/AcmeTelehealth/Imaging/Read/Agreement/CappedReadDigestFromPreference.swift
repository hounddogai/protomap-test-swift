import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLegacyModalityPreferencesForDigest(_ items: [LegacyModalityPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveCappedReadDigestsFromPreference(_ items: [LegacyModalityPreference]) -> [CappedReadDigest] {
        var out: [CappedReadDigest] = []
        for item in items {
            let derived = newCappedReadDigest(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeCappedReadDigest(_ item: CappedReadDigest) -> String {
        return classifyRollingModalityAudit(item.adjustedLoad())
    }
}
