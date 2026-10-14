import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityProfilesForMetric(_ items: [ModalityProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveLenientStudyMetricsFromProfile(_ items: [ModalityProfile]) -> [LenientStudyMetric] {
        var out: [LenientStudyMetric] = []
        for item in items {
            let derived = newLenientStudyMetric(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeLenientStudyMetric(_ item: LenientStudyMetric) -> Double {
        return modalityDraftWeight(4, active: true)
    }
}
