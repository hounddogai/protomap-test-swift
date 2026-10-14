import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeTieredRecallSummariesForGroup(_ items: [TieredRecallSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyFormularyGroupsFromSummary(_ items: [TieredRecallSummary]) -> [LegacyFormularyGroup] {
        var out: [LegacyFormularyGroup] = []
        for item in items {
            let derived = newLegacyFormularyGroup(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeLegacyFormularyGroup(_ item: LegacyFormularyGroup) -> String {
        return normalizeRecallBundleCode(item.code)
    }
}
