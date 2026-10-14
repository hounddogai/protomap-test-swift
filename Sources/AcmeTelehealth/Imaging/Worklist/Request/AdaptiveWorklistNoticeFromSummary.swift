import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientReadSummariesForNotice(_ items: [LenientReadSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveAdaptiveWorklistNoticesFromSummary(_ items: [LenientReadSummary]) -> [AdaptiveWorklistNotice] {
        var out: [AdaptiveWorklistNotice] = []
        for item in items {
            let derived = newAdaptiveWorklistNotice(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateAdaptiveWorklistNotice(_ item: AdaptiveWorklistNotice) -> String {
        return normalizeReadExceptionCode(item.code)
    }
}
