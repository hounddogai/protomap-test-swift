import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeTieredDispenseMetricsForDraft(_ items: [TieredDispenseMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveLenientFormularyDraftsFromMetric(_ items: [TieredDispenseMetric]) -> [LenientFormularyDraft] {
        var out: [LenientFormularyDraft] = []
        for item in items {
            let derived = newLenientFormularyDraft(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planLenientFormularyDraft(_ item: LenientFormularyDraft) -> String {
        return normalizeTieredDispenseMetricCode(item.code)
    }
}
