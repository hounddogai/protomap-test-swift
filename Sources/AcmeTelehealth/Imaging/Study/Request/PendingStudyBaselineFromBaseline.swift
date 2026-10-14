import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadBaselinesForBaseline(_ items: [ReadBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingStudyBaselinesFromBaseline(_ items: [ReadBaseline]) -> [PendingStudyBaseline] {
        var out: [PendingStudyBaseline] = []
        for item in items {
            let derived = newPendingStudyBaseline(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergePendingStudyBaseline(_ item: PendingStudyBaseline) -> String {
        return normalizeReadQuotaCode(item.code)
    }
}
